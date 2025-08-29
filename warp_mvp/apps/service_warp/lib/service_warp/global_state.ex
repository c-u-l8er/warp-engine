defmodule ServiceWarp.GlobalState do
  use GenServer
  require Logger

  @moduledoc """
  Global state management for ServiceWarp, including jobs, technicians, and metrics.
  Integrates with WarpEngine for spatial data storage and queries.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("GlobalState initialized with empty state")
    # Initialize with empty state
    initial_state = %{
      jobs: [],
      technicians: [],
      companies: [],
      metrics: %{
        total_jobs: 0,
        total_technicians: 0,
        jobs_completed: 0,
        jobs_assigned: 0,
        avg_response_time: 0
      }
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    Logger.info("GlobalState: get_state called, returning #{length(state.jobs)} jobs, #{length(state.technicians)} technicians")
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_company_jobs, company_id}, _from, state) do
    company_jobs = Enum.filter(state.jobs, & &1.company_id == company_id)
    Logger.info("GlobalState: get_company_jobs for #{company_id}, returning #{length(company_jobs)} jobs")
    {:reply, company_jobs, state}
  end

  @impl true
  def handle_call({:get_company_technicians, company_id}, _from, state) do
    company_technicians = Enum.filter(state.technicians, & &1.company_id == company_id)
    Logger.info("GlobalState: get_company_technicians for #{company_id}, returning #{length(company_technicians)} technicians")
    {:reply, company_technicians, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = calculate_metrics(state)
    Logger.info("GlobalState: get_metrics called, returning #{inspect(metrics)}")
    {:reply, metrics, state}
  end

  @impl true
  def handle_cast({:add_company, company}, state) do
    Logger.info("GlobalState: Adding company #{company.id} - #{company.name}")

    # Add to local state
    updated_companies = [company | state.companies]
    updated_state = %{state | companies: updated_companies}

    Logger.info("GlobalState: Company added, total companies now: #{length(updated_companies)}")

    # Broadcast company creation event
    Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "companies", {:company_created, company})

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:add_job, job}, state) do
    Logger.info("GlobalState: Adding job #{job.id} - #{job.title}")

    # Store in WarpEngine for spatial queries
    WarpEngine.put("job_#{job.id}", %{
      coordinates: job.coordinates,
      properties: %{
        id: job.id,
        title: job.title,
        status: job.status,
        priority: job.priority,
        company_id: job.company_id,
        required_skills: job.required_skills
      }
    })

    # Add to local state
    updated_jobs = [job | state.jobs]
    updated_state = %{state | jobs: updated_jobs}

    Logger.info("GlobalState: Job added, total jobs now: #{length(updated_jobs)}")

    # Broadcast job creation event
    Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_created, job})

    # Update metrics
    updated_metrics = calculate_metrics(updated_state)
    final_state = %{updated_state | metrics: updated_metrics}

    {:noreply, final_state}
  end

  @impl true
  def handle_cast({:add_technician, technician}, state) do
    Logger.info("GlobalState: Adding technician #{technician.id} - #{technician.name}")

    # Store in WarpEngine for spatial queries
    WarpEngine.put("technician_#{technician.id}", %{
      coordinates: technician.coordinates,
      properties: %{
        id: technician.id,
        name: technician.name,
        status: technician.status,
        skills: technician.skills,
        company_id: technician.company_id,
        rating: technician.rating
      }
    })

    # Add to local state
    updated_technicians = [technician | state.technicians]
    updated_state = %{state | technicians: updated_technicians}

    Logger.info("GlobalState: Technician added, total technicians now: #{length(updated_technicians)}")

    # Broadcast technician addition event
    Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "technicians", {:technician_added, technician})

    # Update metrics
    updated_metrics = calculate_metrics(updated_state)
    final_state = %{updated_state | metrics: updated_metrics}

    {:noreply, final_state}
  end

  @impl true
  def handle_cast({:update_technician_location, technician_id, coordinates}, state) do
    # Update in WarpEngine
    case Enum.find(state.technicians, & &1.id == technician_id) do
      nil ->
        Logger.warning("GlobalState: Technician #{technician_id} not found for location update")
        {:noreply, state}

      technician ->
        updated_technician = %{technician | coordinates: coordinates}

        # Update WarpEngine
        WarpEngine.put("technician_#{technician_id}", %{
          coordinates: coordinates,
          properties: %{
            id: technician_id,
            name: updated_technician.name,
            status: updated_technician.status,
            skills: updated_technician.skills,
            company_id: updated_technician.company_id,
            rating: updated_technician.rating
          }
        })

        # Update local state
        updated_technicians = Enum.map(state.technicians, fn t ->
          if t.id == technician_id, do: updated_technician, else: t
        end)

        updated_state = %{state | technicians: updated_technicians}

        # Broadcast location update event
        Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "technicians", {:location_updated, updated_technician})

        {:noreply, updated_state}
    end
  end

  @impl true
  def handle_call({:update_job_assignment, job_id, technician_id}, _from, state) do
    Logger.info("GlobalState: Updating job assignment for job #{job_id} to technician #{technician_id}")

    # Update job assignment
    case Enum.find(state.jobs, & &1.id == job_id) do
      nil ->
        Logger.warning("GlobalState: Job #{job_id} not found for assignment update")
        {:reply, {:error, :job_not_found}, state}

      job ->
        updated_job =
          job
          |> Map.put(:assigned_technician_id, technician_id)
          |> Map.put(:status, "assigned")

        # Optionally update the assigned technician to working
        {updated_technicians, maybe_updated_tech} =
          case Enum.find(state.technicians, & &1.id == technician_id) do
            nil ->
              {state.technicians, nil}
            tech ->
              updated_tech = tech |> Map.put(:status, "working") |> Map.put(:current_job_id, job_id)

              WarpEngine.put("technician_#{technician_id}", %{
                coordinates: updated_tech.coordinates,
                properties: %{
                  id: technician_id,
                  name: updated_tech.name,
                  status: updated_tech.status,
                  skills: updated_tech.skills,
                  company_id: updated_tech.company_id,
                  rating: updated_tech.rating
                }
              })

              {
                Enum.map(state.technicians, fn t -> if t.id == technician_id, do: updated_tech, else: t end),
                updated_tech
              }
          end

        # Update WarpEngine (job)
        WarpEngine.put("job_#{job_id}", %{
          coordinates: updated_job.coordinates,
          properties: %{
            id: job_id,
            title: updated_job.title,
            status: updated_job.status,
            priority: updated_job.priority,
            company_id: updated_job.company_id,
            required_skills: updated_job.required_skills,
            assigned_technician_id: technician_id
          }
        })

        # Update local state
        updated_jobs = Enum.map(state.jobs, fn j ->
          if j.id == job_id, do: updated_job, else: j
        end)

        updated_state = %{state | jobs: updated_jobs, technicians: updated_technicians}

        Logger.info("GlobalState: Job assignment updated successfully")

        # Broadcast events
        Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_assigned, updated_job})
        if maybe_updated_tech, do: Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "technicians", {:technician_updated, maybe_updated_tech})

        # Update metrics
        updated_metrics = calculate_metrics(updated_state)
        final_state = %{updated_state | metrics: updated_metrics}

        {:reply, {:ok, updated_job}, final_state}
    end
  end

  @impl true
  def handle_call({:unassign_job, job_id}, _from, state) do
    Logger.info("GlobalState: Unassigning job #{job_id}")

    case Enum.find(state.jobs, & &1.id == job_id) do
      nil ->
        Logger.warning("GlobalState: Job #{job_id} not found for unassignment")
        {:reply, {:error, :job_not_found}, state}

      job ->
        prev_tech_id = Map.get(job, :assigned_technician_id)

        updated_job = job |> Map.put(:assigned_technician_id, nil) |> Map.put(:status, "scheduled")

        WarpEngine.put("job_#{job_id}", %{
          coordinates: updated_job.coordinates,
          properties: %{
            id: job_id,
            title: updated_job.title,
            status: updated_job.status,
            priority: updated_job.priority,
            company_id: updated_job.company_id,
            required_skills: updated_job.required_skills,
            assigned_technician_id: nil
          }
        })

        # Update technician back to available if found
        {updated_technicians, maybe_updated_tech} =
          case prev_tech_id && Enum.find(state.technicians, & &1.id == prev_tech_id) do
            nil -> {state.technicians, nil}
            tech ->
              updated_tech = tech |> Map.put(:status, "available") |> Map.put(:current_job_id, nil)

              WarpEngine.put("technician_#{prev_tech_id}", %{
                coordinates: updated_tech.coordinates,
                properties: %{
                  id: prev_tech_id,
                  name: updated_tech.name,
                  status: updated_tech.status,
                  skills: updated_tech.skills,
                  company_id: updated_tech.company_id,
                  rating: updated_tech.rating
                }
              })

              {
                Enum.map(state.technicians, fn t -> if t.id == prev_tech_id, do: updated_tech, else: t end),
                updated_tech
              }
          end

        updated_jobs = Enum.map(state.jobs, fn j -> if j.id == job_id, do: updated_job, else: j end)
        updated_state = %{state | jobs: updated_jobs, technicians: updated_technicians}

        Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_unassigned, updated_job})
        if maybe_updated_tech, do: Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "technicians", {:technician_updated, maybe_updated_tech})

        updated_metrics = calculate_metrics(updated_state)
        final_state = %{updated_state | metrics: updated_metrics}

        {:reply, {:ok, updated_job}, final_state}
    end
  end

  @impl true
  def handle_cast({:update_job_status, job_id, status}, state) do
    Logger.info("GlobalState: Updating job #{job_id} status to #{status}")

    # Update job status
    case Enum.find(state.jobs, & &1.id == job_id) do
      nil ->
        Logger.warning("GlobalState: Job #{job_id} not found for status update")
        {:noreply, state}

      job ->
        updated_job = %{job | status: status}

        # Update WarpEngine
        WarpEngine.put("job_#{job_id}", %{
          coordinates: updated_job.coordinates,
          properties: %{
            id: job_id,
            title: updated_job.title,
            status: status,
            priority: updated_job.priority,
            company_id: updated_job.company_id,
            required_skills: updated_job.required_skills,
            assigned_technician_id: Map.get(updated_job, :assigned_technician_id)
          }
        })

        # Update local state
        updated_jobs = Enum.map(state.jobs, fn j ->
          if j.id == job_id, do: updated_job, else: j
        end)

        updated_state = %{state | jobs: updated_jobs}

        Logger.info("GlobalState: Job status updated successfully")

        # Broadcast job status update event
        Phoenix.PubSub.broadcast(ServiceWarp.PubSub, "jobs", {:job_status_updated, updated_job})

        # Update metrics
        updated_metrics = calculate_metrics(updated_state)
        final_state = %{updated_state | metrics: updated_metrics}

        {:noreply, final_state}
    end
  end

  # Client API functions

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def get_company_jobs(company_id) do
    GenServer.call(__MODULE__, {:get_company_jobs, company_id})
  end

  def get_company_technicians(company_id) do
    GenServer.call(__MODULE__, {:get_company_technicians, company_id})
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  def add_job(job) do
    GenServer.cast(__MODULE__, {:add_job, job})
  end

  def add_technician(technician) do
    GenServer.cast(__MODULE__, {:add_technician, technician})
  end

  def add_company(company) do
    GenServer.cast(__MODULE__, {:add_company, company})
  end

  def update_technician_location(technician_id, coordinates) do
    GenServer.cast(__MODULE__, {:update_technician_location, technician_id, coordinates})
  end

  def update_job_assignment(job_id, technician_id) do
    GenServer.call(__MODULE__, {:update_job_assignment, job_id, technician_id})
  end

  def update_job_status(job_id, status) do
    GenServer.cast(__MODULE__, {:update_job_status, job_id, status})
  end

  def unassign_job(job_id) do
    GenServer.call(__MODULE__, {:unassign_job, job_id})
  end

  # Private functions

  defp calculate_metrics(state) do
    total_jobs = length(state.jobs)
    completed_jobs = Enum.count(state.jobs, & &1.status == "completed")
    assigned_jobs = Enum.count(state.jobs, & &1.status == "assigned")
    total_technicians = length(state.technicians)

    Logger.info("GlobalState: Calculating metrics - #{total_jobs} jobs, #{total_technicians} technicians")

    %{
      total_jobs: total_jobs,
      total_technicians: total_technicians,
      jobs_completed: completed_jobs,
      jobs_assigned: assigned_jobs,
      avg_response_time: calculate_avg_response_time(state.jobs)
    }
  end

  defp calculate_avg_response_time(jobs) do
    # Placeholder calculation - in real app would use actual timestamps
    case length(jobs) do
      0 -> 0
      _ -> Enum.random(15..45) # Random response time for demo
    end
  end
end
