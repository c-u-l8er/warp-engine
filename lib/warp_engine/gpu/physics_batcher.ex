defmodule WarpEngine.GPU.PhysicsBatcher do
  @moduledoc """
  Global GPU physics batcher with size- and time-based flushing.

  - Enqueue physics operations from anywhere (IntelligentRouter).
  - Flush when queue length >= :gpu_batch_size, or when the oldest item
    waits longer than :gpu_flush_interval_ms.
  - Runs GPU work asynchronously; does not block the caller.
  """

  use GenServer
  require Logger

  @name __MODULE__

  # Public API

  @doc """
  Start the batcher. Idempotent (returns :ignore if already started).
  Reads configuration from Application env:
    :warp_engine, :gpu_batch_size (default 256)
    :warp_engine, :gpu_flush_interval_ms (default 10)
    :warp_engine, :gpu_max_queue (optional)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @doc """
  Enqueue a physics operation map. Returns :ok.
  """
  def enqueue(operation) when is_map(operation) do
    if Process.whereis(@name) do
      GenServer.cast(@name, {:enqueue, operation})
      :ok
    else
      # If batcher not running, fall back to immediate async processing for resilience
      Task.start(fn ->
        _ = WarpEngine.GPU.PhysicsEngine.process_physics_batch([operation])
      end)
      :ok
    end
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    batch_size = Application.get_env(:warp_engine, :gpu_batch_size, 256)
    flush_ms = Application.get_env(:warp_engine, :gpu_flush_interval_ms, 10)
    max_queue = Application.get_env(:warp_engine, :gpu_max_queue)

    state = %{
      queue: [],
      timer_ref: nil,
      inflight: false,
      batch_size: normalize_positive_int(batch_size, 256),
      flush_ms: normalize_positive_int(flush_ms, 10),
      max_queue: max_queue
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:enqueue, operation}, state) do
    queue1 = [operation | state.queue]

    # Optional backpressure
    queue2 =
      case state.max_queue do
        m when is_integer(m) and m > 0 -> Enum.take(queue1, m)
        _ -> queue1
      end

    state1 = maybe_start_timer(%{state | queue: queue2})

    if length(state1.queue) >= state1.batch_size do
      {:noreply, flush_now(state1)}
    else
      {:noreply, state1}
    end
  end

  @impl true
  def handle_info(:flush, state) do
    {:noreply, flush_now(%{state | timer_ref: nil})}
  end

  @impl true
  def handle_info({:batch_done, _result}, state) do
    state1 = %{state | inflight: false}
    # If more work is queued, flush immediately to keep GPU fed
    if state1.queue != [] do
      {:noreply, flush_now(state1)}
    else
      {:noreply, state1}
    end
  end

  # Internal helpers

  defp maybe_start_timer(%{timer_ref: nil, flush_ms: ms} = state) do
    if state.queue == [] do
      state
    else
      ref = Process.send_after(self(), :flush, ms)
      %{state | timer_ref: ref}
    end
  end
  defp maybe_start_timer(state), do: state

  defp flush_now(%{queue: []} = state), do: maybe_cancel_timer(state)
  defp flush_now(%{queue: _queue, inflight: true} = state) do
    # Already running a batch; ensure a timer will check again soon
    maybe_start_timer(state)
  end
  defp flush_now(%{queue: queue, inflight: false} = state) do
    # Reverse to preserve enqueue order
    batch = Enum.reverse(queue)
    _ = launch_gpu_batch_async(batch)
    state
    |> Map.put(:queue, [])
    |> Map.put(:inflight, true)
    |> maybe_cancel_timer()
  end

  defp launch_gpu_batch_async(batch) do
    parent = self()
    Task.start(fn ->
      result =
        case WarpEngine.GPU.PhysicsEngine.process_physics_batch(batch) do
          {:ok, _results} -> :ok
          {:error, reason} ->
            Logger.debug("Physics batch failed: #{inspect(reason)}")
            {:error, reason}
          other ->
            Logger.debug("Physics batch returned: #{inspect(other)}")
            other
        end
      send(parent, {:batch_done, result})
    end)
  end

  defp maybe_cancel_timer(%{timer_ref: nil} = state), do: state
  defp maybe_cancel_timer(%{timer_ref: ref} = state) do
    _ = Process.cancel_timer(ref)
    %{state | timer_ref: nil}
  end

  defp normalize_positive_int(val, default) do
    case val do
      v when is_integer(v) and v > 0 -> v
      _ -> default
    end
  end
end
