defmodule ServiceWarp.Agents.JobAssignmentAgent do
  @moduledoc """
  AI-powered job assignment agent that uses spatial intelligence.

  This agent analyzes job requirements, technician availability, and spatial proximity
  to make optimal job assignments.
  """

  use GenServer
  require Logger

  @doc """
  Starts the job assignment agent.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Assigns a job to the best available technician.
  """
  def assign_job(job) do
    GenServer.call(__MODULE__, {:assign_job, job})
  end

  @doc """
  Gets assignment statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      total_assignments: 0,
      successful_assignments: 0,
      failed_assignments: 0,
      average_assignment_time: 0,
      last_assignment: nil
    }}
  end

  @impl true
  def handle_call({:assign_job, job}, _from, state) do
    start_time = System.monotonic_time(:millisecond)

    Logger.info("Job Assignment Agent: Assigning job #{job.id} at #{inspect(job.coordinates)}")

    case find_best_technician(job) do
      {:ok, technician} ->
        # Assign the job
        assign_job_to_technician(job, technician)

        # Update stats
        assignment_time = System.monotonic_time(:millisecond) - start_time
        new_state = update_assignment_stats(state, :success, assignment_time)

        Logger.info("Job Assignment Agent: Successfully assigned job #{job.id} to technician #{technician.id}")
        {:reply, {:ok, technician}, new_state}

      {:error, reason} ->
        # Update stats
        assignment_time = System.monotonic_time(:millisecond) - start_time
        new_state = update_assignment_stats(state, :failure, assignment_time)

        Logger.warning("Job Assignment Agent: Failed to assign job #{job.id}: #{reason}")
        {:reply, {:error, reason}, new_state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  # Private Functions

  defp find_best_technician(job) do
    # Get all available technicians for the company
    available_technicians = get_available_technicians(job.company_id)

    if Enum.empty?(available_technicians) do
      {:error, "No available technicians"}
    else
      # Filter by required skills
      qualified_technicians = filter_by_skills(available_technicians, job.required_skills)

      if Enum.empty?(qualified_technicians) do
        {:error, "No technicians with required skills: #{inspect(job.required_skills)}"}
      else
        # Find the best technician using spatial intelligence
        best_technician = find_nearest_qualified_technician(job, qualified_technicians)
        {:ok, best_technician}
      end
    end
  end

  defp get_available_technicians(company_id) do
    # This would typically query a database or state store
    # For now, we'll return an empty list - this will be implemented later
    []
  end

  defp filter_by_skills(technicians, required_skills) do
    Enum.filter(technicians, &ServiceWarp.Technicians.Technician.has_skills?(&1, required_skills))
  end

  defp find_nearest_qualified_technician(job, technicians) do
    # Use WarpEngine to find the nearest technician
    job_location = ServiceWarp.Jobs.Job.location(job)

    # For now, just return the first technician
    # Later this will use WarpEngine.radius_search for spatial optimization
    List.first(technicians)
  end

  defp assign_job_to_technician(job, technician) do
    # This would typically update the database and notify the technician
    # For now, we'll just log the assignment
    Logger.info("Assigning job #{job.id} to technician #{technician.id}")

    # Update job status
    updated_job = ServiceWarp.Jobs.Job.assign_technician(job, technician.id)

    # Update technician status
    updated_technician = ServiceWarp.Technicians.Technician.assign_job(technician, job.id)

    # Broadcast the assignment
    Phoenix.PubSub.broadcast(
      ServiceWarp.PubSub,
      "company:#{job.company_id}:job_assignments",
      {:job_assigned, updated_job, updated_technician}
    )
  end

  defp update_assignment_stats(state, :success, assignment_time) do
    total = state.total_assignments + 1
    successful = state.successful_assignments + 1

    # Calculate running average
    current_avg = state.average_assignment_time
    new_avg = ((current_avg * (total - 1)) + assignment_time) / total

    %{state |
      total_assignments: total,
      successful_assignments: successful,
      average_assignment_time: new_avg,
      last_assignment: DateTime.utc_now()
    }
  end

  defp update_assignment_stats(state, :failure, assignment_time) do
    total = state.total_assignments + 1
    failed = state.failed_assignments + 1

    # Calculate running average
    current_avg = state.average_assignment_time
    new_avg = ((current_avg * (total - 1)) + assignment_time) / total

    %{state |
      total_assignments: total,
      failed_assignments: failed,
      average_assignment_time: new_avg,
      last_assignment: DateTime.utc_now()
    }
  end
end
