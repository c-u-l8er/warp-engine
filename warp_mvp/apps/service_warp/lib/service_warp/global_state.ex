defmodule ServiceWarp.GlobalState do
  @moduledoc """
  Global state manager for ServiceWarp.

  This module manages system-wide state including:
  - Active jobs and technicians
  - Spatial intelligence data
  - System performance metrics
  - Real-time coordination
  """

  use GenServer
  require Logger

  @doc """
  Starts the global state manager.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current system state.
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Gets active jobs for a company.
  """
  def get_company_jobs(company_id) do
    GenServer.call(__MODULE__, {:get_company_jobs, company_id})
  end

  @doc """
  Gets active technicians for a company.
  """
  def get_company_technicians(company_id) do
    GenServer.call(__MODULE__, {:get_company_technicians, company_id})
  end

  @doc """
  Adds a job to the system.
  """
  def add_job(job) do
    GenServer.call(__MODULE__, {:add_job, job})
  end

  @doc """
  Adds a technician to the system.
  """
  def add_technician(technician) do
    GenServer.call(__MODULE__, {:add_technician, technician})
  end

  @doc """
  Updates a technician's location.
  """
  def update_technician_location(technician_id, coordinates) do
    GenServer.call(__MODULE__, {:update_technician_location, technician_id, coordinates})
  end

  @doc """
  Gets system performance metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    # Initialize with empty state
    initial_state = %{
      companies: %{},
      jobs: %{},
      technicians: %{},
      metrics: %{
        total_jobs: 0,
        active_jobs: 0,
        total_technicians: 0,
        active_technicians: 0,
        jobs_completed_today: 0,
        average_response_time: 0
      },
      spatial_data: %{
        gravity_wells: [],
        entropy_zones: [],
        quantum_entanglements: []
      }
    }

    # Start monitoring
    schedule_metrics_update()

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_company_jobs, company_id}, _from, state) do
    company_jobs = Map.values(state.jobs)
    |> Enum.filter(&(&1.company_id == company_id))

    {:reply, company_jobs, state}
  end

  @impl true
  def handle_call({:get_company_technicians, company_id}, _from, state) do
    company_technicians = Map.values(state.technicians)
    |> Enum.filter(&(&1.company_id == company_id))

    {:reply, company_technicians, state}
  end

  @impl true
  def handle_call({:add_job, job}, _from, state) do
    new_jobs = Map.put(state.jobs, job.id, job)

    # Update metrics
    new_metrics = update_job_metrics(state.metrics, :add)

    # Update spatial data in WarpEngine
    store_job_in_warp_engine(job)

    new_state = %{state |
      jobs: new_jobs,
      metrics: new_metrics
    }

    # Broadcast job creation
    broadcast_job_event(:job_created, job)

    {:reply, {:ok, job}, new_state}
  end

  @impl true
  def handle_call({:add_technician, technician}, _from, state) do
    new_technicians = Map.put(state.technicians, technician.id, technician)

    # Update metrics
    new_metrics = update_technician_metrics(state.metrics, :add)

    # Update spatial data in WarpEngine
    store_technician_in_warp_engine(technician)

    new_state = %{state |
      technicians: new_technicians,
      metrics: new_metrics
    }

    # Broadcast technician addition
    broadcast_technician_event(:technician_added, technician)

    {:reply, {:ok, technician}, new_state}
  end

  @impl true
  def handle_call({:update_technician_location, technician_id, coordinates}, _from, state) do
    case Map.get(state.technicians, technician_id) do
      nil ->
        {:reply, {:error, :technician_not_found}, state}

      technician ->
        updated_technician = ServiceWarp.Technicians.Technician.update_location(technician, coordinates)
        new_technicians = Map.put(state.technicians, technician_id, updated_technician)

        # Update location in WarpEngine
        update_technician_location_in_warp_engine(technician_id, coordinates)

        new_state = %{state | technicians: new_technicians}

        # Broadcast location update
        broadcast_technician_event(:location_updated, updated_technician)

        {:reply, {:ok, updated_technician}, new_state}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  @impl true
  def handle_info(:update_metrics, state) do
    # Update metrics every minute
    new_metrics = calculate_current_metrics(state)
    new_state = %{state | metrics: new_metrics}

    schedule_metrics_update()
    {:noreply, new_state}
  end

  # Private Functions

  defp schedule_metrics_update do
    Process.send_after(self(), :update_metrics, 60_000) # Every minute
  end

  defp update_job_metrics(metrics, :add) do
    %{metrics |
      total_jobs: metrics.total_jobs + 1,
      active_jobs: metrics.active_jobs + 1
    }
  end

  defp update_technician_metrics(metrics, :add) do
    %{metrics |
      total_technicians: metrics.total_technicians + 1,
      active_technicians: metrics.active_technicians + 1
    }
  end

  defp calculate_current_metrics(state) do
    active_jobs = Map.values(state.jobs)
    |> Enum.count(&(&1.status in [:pending, :assigned, :in_progress]))

    active_technicians = Map.values(state.technicians)
    |> Enum.count(&(&1.status == :available))

    %{state.metrics |
      active_jobs: active_jobs,
      active_technicians: active_technicians
    }
  end

  defp store_job_in_warp_engine(job) do
    # Store job location in WarpEngine for spatial queries
    WarpEngine.put("job_#{job.id}", %{
      coordinates: job.coordinates,
      properties: %{
        id: job.id,
        type: "job",
        status: job.status,
        priority: job.priority,
        company_id: job.company_id,
        required_skills: job.required_skills
      }
    })
  end

  defp store_technician_in_warp_engine(technician) do
    # Store technician location in WarpEngine for spatial queries
    WarpEngine.put("technician_#{technician.id}", %{
      coordinates: technician.coordinates,
      properties: %{
        id: technician.id,
        type: "technician",
        status: technician.status,
        skills: technician.skills,
        company_id: technician.company_id,
        experience_level: technician.experience_level
      }
    })
  end

  defp update_technician_location_in_warp_engine(technician_id, coordinates) do
    # Update technician location in WarpEngine
    WarpEngine.put("technician_#{technician_id}", %{
      coordinates: coordinates,
      properties: %{
        id: technician_id,
        type: "technician",
        updated_at: DateTime.utc_now()
      }
    })
  end

  defp broadcast_job_event(event, job) do
    Phoenix.PubSub.broadcast(
      ServiceWarp.PubSub,
      "company:#{job.company_id}:jobs",
      {event, job}
    )
  end

  defp broadcast_technician_event(event, technician) do
    Phoenix.PubSub.broadcast(
      ServiceWarp.PubSub,
      "company:#{technician.company_id}:technicians",
      {event, technician}
    )
  end
end
