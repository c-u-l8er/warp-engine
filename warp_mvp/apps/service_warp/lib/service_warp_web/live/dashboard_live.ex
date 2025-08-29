defmodule ServiceWarpWeb.DashboardLive do
  use ServiceWarpWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    # Always check if we need demo data, regardless of socket connection
    current_state = ServiceWarp.GlobalState.get_state()
    Logger.info("Current state: #{inspect(current_state)}")

    if current_state.jobs == [] do
      Logger.info("Creating demo data...")
      create_demo_data()
    else
      Logger.info("Demo data already exists: #{length(current_state.jobs)} jobs, #{length(current_state.technicians)} technicians")
    end

    if connected?(socket) do
      # Set up periodic updates only if connected
      :timer.send_interval(5000, self(), :update_metrics)
      Logger.info("Socket connected, periodic updates enabled")
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "jobs")
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "technicians")
    else
      Logger.info("Socket not connected, periodic updates disabled")
    end

    {:ok, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    {:noreply, assign_dashboard_data(socket)}
  end

  # Reflect job events broadcast from GlobalState/AI
  def handle_info({:job_created, _job}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:job_assigned, _job_id, _tech_id}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:job_assigned, _job}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:job_status_updated, _job}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:job_unassigned, _job}, socket), do: {:noreply, assign_dashboard_data(socket)}

  # Reflect technician events
  def handle_info({:technician_added, _tech}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:location_updated, _tech}, socket), do: {:noreply, assign_dashboard_data(socket)}
  def handle_info({:technician_updated, _tech}, socket), do: {:noreply, assign_dashboard_data(socket)}

  @impl true
  def handle_event("create_demo_data", _params, socket) do
    Logger.info("Manual demo data creation triggered")
    create_demo_data()
    {:noreply, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_event("assign_job", %{"job_id" => job_id, "technician_id" => technician_id}, socket) do
    # Use the AI agent to assign the job
    ServiceWarp.Agents.JobAssignmentAgent.assign_job(%{
      job_id: job_id,
      technician_id: technician_id
    })
    {:noreply, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_event("assign_job", %{"job_id" => job_id}, socket) do
    # AI assignment by job id
    state = ServiceWarp.GlobalState.get_state()
    case Enum.find(state.jobs, &(&1.id == job_id)) do
      nil -> :noop
      job -> ServiceWarp.Agents.JobAssignmentAgent.assign_job(%{job_id: job_id, company_id: job.company_id})
    end
    {:noreply, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_event("update_technician_location", %{"technician_id" => tech_id, "lat" => lat, "lng" => lng}, socket) do
    # Simulate technician movement
    ServiceWarp.GlobalState.update_technician_location(tech_id, {String.to_float(lat), String.to_float(lng)})
    {:noreply, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_event("complete_job", %{"job_id" => job_id}, socket) do
    # Mark job as completed
    ServiceWarp.GlobalState.update_job_status(job_id, "completed")
    {:noreply, assign_dashboard_data(socket)}
  end

  defp assign_dashboard_data(socket) do
    state = ServiceWarp.GlobalState.get_state()
    Logger.info("Assigning dashboard data: #{length(state.jobs)} jobs, #{length(state.technicians)} technicians")

    socket
    |> assign(:jobs, state.jobs)
    |> assign(:technicians, state.technicians)
    |> assign(:metrics, calculate_metrics(state))
    |> assign(:urgent_jobs, filter_urgent_jobs(state.jobs))
    |> assign(:available_technicians, filter_available_technicians(state.technicians))
    |> assign(:working_technicians, filter_working_technicians(state.technicians))
    |> assign(:recent_activity, get_recent_activity(state))
  end

  def create_demo_data do
    Logger.info("Starting demo data creation...")

    # Create demo company
    company = ServiceWarp.Accounts.Company.new(%{
      name: "Demo Field Services Inc.",
      industry: "Multi-Service",
      coordinates: {37.7749, -122.4194}, # San Francisco
      subscription_plan: "Professional",
      technician_limit: 25,
      active_technicians: 0
    })

    Logger.info("Created company: #{inspect(company)}")

    # Add company to GlobalState
    ServiceWarp.GlobalState.add_company(company)

    # Create demo technicians with realistic locations around SF
    technicians = [
      %{
        id: "tech_001",
        name: "John Davis",
        skills: ["HVAC", "Electrical"],
        coordinates: {37.7849, -122.4094}, # Downtown SF
        status: "available",
        rating: 4.8,
        company_id: company.id
      },
      %{
        id: "tech_002",
        name: "Sarah Martinez",
        skills: ["Plumbing", "HVAC"],
        coordinates: {37.7649, -122.4294}, # Mission District
        status: "available",
        rating: 4.9,
        company_id: company.id
      },
      %{
        id: "tech_003",
        name: "Mike Rodriguez",
        skills: ["Electrical", "Security"],
        coordinates: {37.7949, -122.3994}, # North Beach
        status: "available",
        rating: 4.7,
        company_id: company.id
      },
      %{
        id: "tech_004",
        name: "Lisa Kim",
        skills: ["HVAC", "Plumbing"],
        coordinates: {37.7549, -122.4394}, # Potrero Hill
        status: "available",
        rating: 4.6,
        company_id: company.id
      },
      %{
        id: "tech_005",
        name: "David Thompson",
        skills: ["Security", "Electrical"],
        coordinates: {37.8049, -122.3894}, # Fisherman's Wharf
        status: "available",
        rating: 4.5,
        company_id: company.id
      }
    ]

    # Create demo jobs with realistic locations
    jobs = [
      %{
        id: "job_001",
        title: "HVAC Emergency - No Heat",
        description: "Residential heating system failure, elderly resident",
        coordinates: {37.7749, -122.4194}, # Union Square
        required_skills: ["HVAC"],
        status: "urgent",
        priority: "high",
        customer_name: "Mrs. Johnson",
        estimated_duration: 120,
        company_id: company.id
      },
      %{
        id: "job_002",
        title: "Plumbing Leak - Kitchen Sink",
        description: "Water damage under sink, needs immediate attention",
        coordinates: {37.7649, -122.4294}, # Mission District
        required_skills: ["Plumbing"],
        status: "scheduled",
        priority: "medium",
        customer_name: "Cafe Luna",
        estimated_duration: 90,
        company_id: company.id
      },
      %{
        id: "job_003",
        title: "Electrical Panel Upgrade",
        description: "Commercial building electrical upgrade",
        coordinates: {37.7949, -122.3994}, # North Beach
        required_skills: ["Electrical"],
        status: "scheduled",
        priority: "medium",
        customer_name: "North Beach Deli",
        estimated_duration: 240,
        company_id: company.id
      },
      %{
        id: "job_004",
        title: "Security System Installation",
        description: "New office building security setup",
        coordinates: {37.8049, -122.3894}, # Fisherman's Wharf
        required_skills: ["Security"],
        status: "scheduled",
        priority: "low",
        customer_name: "Seafood Market",
        estimated_duration: 180,
        company_id: company.id
      },
      %{
        id: "job_005",
        title: "HVAC Maintenance - Office Building",
        description: "Quarterly maintenance for 5-story office",
        coordinates: {37.7849, -122.4094}, # Financial District
        required_skills: ["HVAC"],
        status: "scheduled",
        priority: "low",
        customer_name: "TechCorp Inc.",
        estimated_duration: 300,
        company_id: company.id
      }
    ]

    Logger.info("Adding #{length(technicians)} technicians to system...")
    # Add all data to the system
    Enum.each(technicians, fn tech ->
      Logger.info("Adding technician: #{tech.name}")
      ServiceWarp.GlobalState.add_technician(tech)
    end)

    Logger.info("Adding #{length(jobs)} jobs to system...")
    Enum.each(jobs, fn job ->
      Logger.info("Adding job: #{job.title}")
      ServiceWarp.GlobalState.add_job(job)
    end)

    # Auto-assign some jobs using AI
    Logger.info("Auto-assigning jobs...")

    # Try to assign job_002 (Plumbing) - this should fail as no available technicians have Plumbing skills
    # This will keep the job as "scheduled" and technicians as "available"
    case ServiceWarp.Agents.JobAssignmentAgent.assign_job(%{job_id: "job_002", company_id: company.id}) do
      {:ok, technician} ->
        Logger.info("Successfully assigned job_002 to #{technician.name}")
      {:error, reason} ->
        Logger.info("Job_002 assignment failed (expected): #{reason}")
    end

    # Try to assign job_004 (Security) - this should succeed as Mike Rodriguez and David Thompson are available
    # This will update the technician status to "working" and job status to "assigned"
    case ServiceWarp.Agents.JobAssignmentAgent.assign_job(%{job_id: "job_004", company_id: company.id}) do
      {:ok, technician} ->
        Logger.info("Successfully assigned job_004 to #{technician.name}")
      {:error, reason} ->
        Logger.warning("Job_004 assignment failed: #{reason}")
    end

    Logger.info("Auto-assignment completed")

    Logger.info("Demo data creation completed!")

    # Verify the data was added
    final_state = ServiceWarp.GlobalState.get_state()
    Logger.info("Final state after demo data creation: #{length(final_state.jobs)} jobs, #{length(final_state.technicians)} technicians")
  end

  defp calculate_metrics(state) do
    total_jobs = length(state.jobs)
    completed_jobs = Enum.count(state.jobs, & &1.status == "completed")
    urgent_jobs = Enum.count(state.jobs, & &1.status == "urgent")
    available_techs = Enum.count(state.technicians, & &1.status == "available")

    Logger.info("Calculating metrics: #{total_jobs} total jobs, #{urgent_jobs} urgent, #{available_techs} available techs")

    %{
      total_jobs: total_jobs,
      completed_jobs: completed_jobs,
      in_progress_jobs: total_jobs - completed_jobs,
      urgent_jobs: urgent_jobs,
      available_technicians: available_techs,
      total_technicians: length(state.technicians),
      completion_rate: if(total_jobs > 0, do: Float.round(completed_jobs / total_jobs * 100, 1), else: 0.0),
      avg_response_time: "23 minutes",
      customer_satisfaction: "4.8/5.0"
    }
  end

  defp filter_urgent_jobs(jobs) do
    urgent = jobs
    |> Enum.filter(fn j -> j.status == "urgent" or j.priority == "high" end)
    |> Enum.sort_by(& &1.priority, :desc)
    |> Enum.take(5)

    Logger.info("Found #{length(urgent)} urgent jobs")
    urgent
  end

  defp filter_available_technicians(technicians) do
    available = technicians
    |> Enum.filter(& &1.status == "available")
    |> Enum.sort_by(& &1.rating, :desc)
    |> Enum.take(5)

    Logger.info("Found #{length(available)} available technicians")
    available
  end

  defp filter_working_technicians(technicians) do
    working = technicians
    |> Enum.filter(& &1.status == "working")
    |> Enum.sort_by(& &1.rating, :desc)
    |> Enum.take(5)

    Logger.info("Found #{length(working)} working technicians")
    working
  end

  defp get_recent_activity(state) do
    # Simulate recent activity
    [
      %{type: "job_assigned", message: "HVAC job assigned to John Davis", time: "2 min ago"},
      %{type: "job_completed", message: "Plumbing repair completed by Sarah Martinez", time: "15 min ago"},
      %{type: "technician_available", message: "Mike Rodriguez is now available", time: "23 min ago"},
      %{type: "new_job", message: "New urgent HVAC request received", time: "45 min ago"}
    ]
  end
end
