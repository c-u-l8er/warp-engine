defmodule ServiceWarpWeb.DashboardLive do
  use ServiceWarpWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    # For demo purposes, we'll use a hardcoded company ID
    company_id = "demo_company_123"

    if connected?(socket) do
      # Subscribe to company-specific updates
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "company:#{company_id}:jobs")
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "company:#{company_id}:technicians")

      # Start periodic updates
      schedule_update()
    end

    # Get initial data
    jobs = ServiceWarp.GlobalState.get_company_jobs(company_id)
    technicians = ServiceWarp.GlobalState.get_company_technicians(company_id)
    metrics = ServiceWarp.GlobalState.get_metrics()

    {:ok,
     socket
     |> assign(:company_id, company_id)
     |> assign(:jobs, jobs)
     |> assign(:technicians, technicians)
     |> assign(:metrics, metrics)
     |> assign(:selected_job, nil)
     |> assign(:selected_technician, nil)
     |> assign(:show_job_modal, false)
     |> assign(:show_technician_modal, false)}
  end

  @impl true
  def handle_info({:job_created, job}, socket) do
    updated_jobs = [job | socket.assigns.jobs]
    updated_metrics = ServiceWarp.GlobalState.get_metrics()

    {:noreply,
     socket
     |> assign(:jobs, updated_jobs)
     |> assign(:metrics, updated_metrics)
     |> put_flash(:info, "New job created: #{job.title}")}
  end

  @impl true
  def handle_info({:job_assigned, job, technician}, socket) do
    updated_jobs = Enum.map(socket.assigns.jobs, fn j ->
      if j.id == job.id, do: job, else: j
    end)

    updated_technicians = Enum.map(socket.assigns.technicians, fn t ->
      if t.id == technician.id, do: technician, else: t
    end)

    {:noreply,
     socket
     |> assign(:jobs, updated_jobs)
     |> assign(:technicians, updated_technicians)
     |> put_flash(:info, "Job assigned to #{technician.name}")}
  end

  @impl true
  def handle_info({:technician_added, technician}, socket) do
    updated_technicians = [technician | socket.assigns.technicians]
    updated_metrics = ServiceWarp.GlobalState.get_metrics()

    {:noreply,
     socket
     |> assign(:technicians, updated_technicians)
     |> assign(:metrics, updated_metrics)
     |> put_flash(:info, "Technician added: #{technician.name}")}
  end

  @impl true
  def handle_info({:location_updated, technician}, socket) do
    updated_technicians = Enum.map(socket.assigns.technicians, fn t ->
      if t.id == technician.id, do: technician, else: t
    end)

    {:noreply, socket |> assign(:technicians, updated_technicians)}
  end

  @impl true
  def handle_info(:update, socket) do
    # Refresh data periodically
    jobs = ServiceWarp.GlobalState.get_company_jobs(socket.assigns.company_id)
    technicians = ServiceWarp.GlobalState.get_company_technicians(socket.assigns.company_id)
    metrics = ServiceWarp.GlobalState.get_metrics()

    schedule_update()

    {:noreply,
     socket
     |> assign(:jobs, jobs)
     |> assign(:technicians, technicians)
     |> assign(:metrics, metrics)}
  end

  @impl true
  def handle_event("select_job", %{"id" => job_id}, socket) do
    job = Enum.find(socket.assigns.jobs, &(&1.id == job_id))
    {:noreply, socket |> assign(:selected_job, job)}
  end

  @impl true
  def handle_event("select_technician", %{"id" => tech_id}, socket) do
    technician = Enum.find(socket.assigns.technicians, &(&1.id == tech_id))
    {:noreply, socket |> assign(:selected_technician, technician)}
  end

  @impl true
  def handle_event("show_job_modal", %{"id" => job_id}, socket) do
    job = Enum.find(socket.assigns.jobs, &(&1.id == job_id))
    {:noreply, socket |> assign(:show_job_modal, true) |> assign(:selected_job, job)}
  end

  @impl true
  def handle_event("close_job_modal", _params, socket) do
    {:noreply, socket |> assign(:show_job_modal, false)}
  end

  @impl true
  def handle_event("assign_job", %{"job_id" => job_id}, socket) do
    job = Enum.find(socket.assigns.jobs, &(&1.id == job_id))

    case ServiceWarp.Agents.JobAssignmentAgent.assign_job(job) do
      {:ok, technician} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job assigned to #{technician.name}")
         |> assign(:show_job_modal, false)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to assign job: #{reason}")
         |> assign(:show_job_modal, false)}
    end
  end

  @impl true
  def handle_event("create_demo_data", _params, socket) do
    # Create some demo data for testing
    create_demo_data(socket.assigns.company_id)

    {:noreply,
     socket
     |> put_flash(:info, "Demo data created! Refresh to see it.")}
  end

  # Private Functions

  defp schedule_update do
    Process.send_after(self(), :update, 5000) # Every 5 seconds
  end

  defp create_demo_data(company_id) do
    # Create demo company
    company = ServiceWarp.Accounts.Company.new(%{
      id: company_id,
      name: "Demo HVAC Company",
      industry: :hvac,
      coordinates: {37.7749, -122.4194}, # San Francisco
      contact_person: "John Manager",
      contact_email: "john@demohvac.com"
    })

    # Create demo technicians
    tech1 = ServiceWarp.Technicians.Technician.new(%{
      name: "Mike Johnson",
      email: "mike@demohvac.com",
      phone: "(555) 123-4567",
      coordinates: {37.7849, -122.4094}, # Near SF
      skills: ["hvac", "repair", "maintenance"],
      experience_level: :senior,
      company_id: company_id
    })

    tech2 = ServiceWarp.Technicians.Technician.new(%{
      name: "Sarah Chen",
      email: "sarah@demohvac.com",
      phone: "(555) 987-6543",
      coordinates: {37.7649, -122.4294}, # Another area in SF
      skills: ["hvac", "installation", "repair"],
      experience_level: :intermediate,
      company_id: company_id
    })

    # Create demo jobs
    job1 = ServiceWarp.Jobs.Job.new(%{
      title: "AC Unit Repair",
      description: "AC not cooling properly, needs diagnosis and repair",
      coordinates: {37.7749, -122.4194},
      address: "123 Market St, San Francisco, CA",
      required_skills: ["hvac", "repair"],
      priority: :high,
      customer_id: "customer_001",
      company_id: company_id
    })

    job2 = ServiceWarp.Jobs.Job.new(%{
      title: "Furnace Maintenance",
      description: "Annual furnace maintenance and inspection",
      coordinates: {37.7849, -122.4094},
      address: "456 Mission St, San Francisco, CA",
      required_skills: ["hvac", "maintenance"],
      priority: :normal,
      customer_id: "customer_002",
      company_id: company_id
    })

    # Add to global state
    ServiceWarp.GlobalState.add_technician(tech1)
    ServiceWarp.GlobalState.add_technician(tech2)
    ServiceWarp.GlobalState.add_job(job1)
    ServiceWarp.GlobalState.add_job(job2)
  end

  defp urgent_jobs(jobs) do
    Enum.filter(jobs, &ServiceWarp.Jobs.Job.urgent?/1)
  end

  defp available_technicians(technicians) do
    Enum.filter(technicians, &ServiceWarp.Technicians.Technician.available?/1)
  end

  defp working_technicians(technicians) do
    Enum.filter(technicians, &ServiceWarp.Technicians.Technician.working?/1)
  end
end
