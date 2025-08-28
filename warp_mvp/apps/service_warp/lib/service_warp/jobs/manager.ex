defmodule ServiceWarp.Jobs.Manager do
  @moduledoc """
  Job Manager for handling job CRUD operations.

  This is a placeholder module that will be implemented later.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
