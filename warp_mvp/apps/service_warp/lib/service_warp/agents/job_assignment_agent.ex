defmodule ServiceWarp.Agents.JobAssignmentAgent do
  use GenServer
  require Logger

  @moduledoc """
  AI-powered job assignment agent for ServiceWarp.
  Uses spatial intelligence and skill matching to optimize job assignments.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("JobAssignmentAgent started")
    {:ok, %{assignments_made: 0, total_jobs: 0}}
  end

  @doc """
  Assigns a job to a technician using AI reasoning.
  """
  def assign_job(%{job_id: job_id, technician_id: technician_id}) do
    GenServer.call(__MODULE__, {:assign_job, job_id, technician_id})
  end

  def assign_job(%{job_id: job_id, company_id: company_id}) do
    # Fetch the full job data from GlobalState
    case get_job_by_id(job_id) do
      nil ->
        {:error, "Job not found: #{job_id}"}
      job ->
        # Add company_id to the job if it's not already there
        job_with_company = %{job | company_id: company_id}
        GenServer.call(__MODULE__, {:assign_job_ai, job_with_company})
    end
  end

  def assign_job(job) do
    GenServer.call(__MODULE__, {:assign_job_ai, job})
  end

  @doc """
  Gets assignment statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # GenServer Callbacks

  @impl true
  def handle_call({:assign_job, job_id, technician_id}, _from, state) do
    # Direct assignment - update the job
    case ServiceWarp.GlobalState.update_job_assignment(job_id, technician_id) do
      {:ok, updated_job} ->
        Logger.info("Job #{job_id} assigned to technician #{technician_id}")

        # Broadcast assignment event
        Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_assigned, job_id, technician_id})

        new_state = %{state |
          assignments_made: state.assignments_made + 1,
          total_jobs: state.total_jobs + 1
        }

        {:reply, {:ok, updated_job}, new_state}

      {:error, reason} ->
        Logger.error("Failed to assign job #{job_id}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:assign_job_ai, job}, _from, state) do
    # AI-powered assignment
    case find_best_technician(job) do
      {:ok, technician} ->
        # Assign the job
        case ServiceWarp.GlobalState.update_job_assignment(job.id, technician.id) do
          {:ok, updated_job} ->
            Logger.info("AI assigned job #{job.id} to #{technician.name}")

            # Broadcast assignment event
            Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_assigned, job.id, technician.id})

            new_state = %{state |
              assignments_made: state.assignments_made + 1,
              total_jobs: state.total_jobs + 1
            }

            {:reply, {:ok, technician}, new_state}

          {:error, reason} ->
            Logger.error("Failed to assign job #{job.id}: #{reason}")
            {:reply, {:error, reason}, state}
        end

      {:error, reason} ->
        Logger.error("No suitable technician found for job #{job.id}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  # Private Functions

  defp find_best_technician(job) do
    Logger.info("Finding best technician for job #{job.id} (requires skills: #{inspect(job.required_skills)})")

    # Get available technicians
    available_techs = get_available_technicians(job.company_id)
    Logger.info("Found #{length(available_techs)} available technicians")

    if available_techs == [] do
      Logger.warning("No available technicians found for company #{job.company_id}")
      {:error, "No available technicians"}
    else
      # Filter by skills
      qualified_techs = filter_by_skills(available_techs, job.required_skills)
      Logger.info("Found #{length(qualified_techs)} technicians with required skills: #{inspect(job.required_skills)}")

      if qualified_techs == [] do
        Logger.warning("No technicians found with required skills: #{inspect(job.required_skills)}")
        {:error, "No technicians with required skills"}
      else
        # Find nearest qualified technician
        best_tech = find_nearest_qualified_technician(job, qualified_techs)
        Logger.info("Selected technician #{best_tech.name} for job #{job.id}")
        {:ok, best_tech}
      end
    end
  end

  defp get_available_technicians(company_id) do
    # Get all technicians from global state for the specific company
    state = ServiceWarp.GlobalState.get_state()
    Enum.filter(state.technicians, fn tech ->
      tech.status == "available" and tech.company_id == company_id
    end)
  end

  defp filter_by_skills(technicians, required_skills) do
    Enum.filter(technicians, fn tech ->
      Enum.all?(required_skills, &(&1 in tech.skills))
    end)
  end

  defp find_nearest_qualified_technician(job, qualified_technicians) do
    job_location = normalize_coordinates(job.coordinates)

    # Find the technician closest to the job
    Enum.min_by(qualified_technicians, fn tech ->
      tech_location = normalize_coordinates(tech.coordinates)
      calculate_distance(job_location, tech_location)
    end)
  end

  defp assign_job_to_technician(job_id, technician_id) do
    # This would update the job assignment in the system
    ServiceWarp.GlobalState.update_job_assignment(job_id, technician_id)
  end

  defp calculate_distance({lat1, lon1}, {lat2, lon2}) do
    # Simple Euclidean distance for demo purposes
    # In production, use Haversine formula for accurate geographic distance
    :math.sqrt((lat2 - lat1) ** 2 + (lon2 - lon1) ** 2)
  end

  defp normalize_coordinates({lat, lng}) when is_number(lat) and is_number(lng) do
    {lat, lng}
  end

  defp normalize_coordinates([lat, lng]) when is_number(lat) and is_number(lng) do
    {lat, lng}
  end

  defp normalize_coordinates(_), do: {0.0, 0.0}

  defp get_job_by_id(job_id) do
    state = ServiceWarp.GlobalState.get_state()
    Enum.find(state.jobs, &(&1.id == job_id))
  end
end
