defmodule ServiceWarpWeb.AIAgentLive do
  use ServiceWarpWeb, :live_view
  import Ecto.Query, only: [from: 2]

  @tick_ms 3_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "jobs")
      Phoenix.PubSub.subscribe(ServiceWarp.PubSub, "technicians")
      :timer.send_interval(@tick_ms, self(), :tick)
    end

    state = ServiceWarp.GlobalState.get_state()
    if state.jobs == [] and state.technicians == [] do
      ServiceWarpWeb.DashboardLive.create_demo_data()
      state = ServiceWarp.GlobalState.get_state()
      stats = ServiceWarp.Agents.JobAssignmentAgent.get_stats()
      {:ok,
        socket
        |> assign(:page_title, "AI Agent")
        |> assign(:logs, [])
        |> assign(:state, state)
        |> assign(:stats, stats)
        |> refresh()}
    else
      stats = ServiceWarp.Agents.JobAssignmentAgent.get_stats()
      {:ok,
        socket
        |> assign(:page_title, "AI Agent")
        |> assign(:logs, [])
        |> assign(:state, state)
        |> assign(:stats, stats)
        |> refresh()}
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_event("auto_assign_all", _params, socket) do
    state = socket.assigns.state

    pending_jobs = state.jobs
    |> Enum.filter(fn j ->
      Map.get(j, :assigned_technician_id) == nil and j.status != "completed"
    end)

    available_technicians = state.technicians
    |> Enum.filter(& &1.status == "available")

    if pending_jobs == [] do
      {:noreply, socket |> push_log("No pending jobs to assign") |> refresh()}
    else
      if available_technicians == [] do
        {:noreply, socket |> push_log("No available technicians for assignment") |> refresh()}
      else
        socket = push_log(socket, "Autogentic analyzing #{length(pending_jobs)} pending jobs...")
        decisions = ServiceWarp.AutogenticAdapter.plan_assignments(pending_jobs, available_technicians)

        {socket, assigned} = Enum.reduce(decisions, {socket, 0}, fn %{job_id: job_id, technician_id: _tech_id}, {acc, count} ->
          case ServiceWarp.Agents.JobAssignmentAgent.assign_job(%{job_id: job_id, company_id: find_company_id(state.jobs, job_id)}) do
            {:ok, tech} -> {push_log(acc, "✅ #{job_id} → #{tech.name}"), count + 1}
            {:error, reason} -> {push_log(acc, "❌ #{job_id}: #{reason}"), count}
          end
        end)

        {:noreply, socket |> push_log("Autogentic completed assignments: #{assigned}") |> refresh()}
      end
    end
  end

  defp find_company_id(jobs, job_id) do
    case Enum.find(jobs, &(&1.id == job_id)) do
      nil -> nil
      job -> job.company_id
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_info({:job_assigned, _job}, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_info({:job_assigned, job_id, technician_id}, socket) do
    {:noreply,
      socket
      |> push_log("Job #{job_id} assigned to #{technician_id}")
      |> refresh()}
  end

  def handle_info({:technician_updated, tech}, socket) do
    {:noreply,
      socket
      |> push_log("Technician #{tech.id} (#{tech.name}) updated - status: #{tech.status}")
      |> refresh()}
  end

  def handle_info({:technician_added, tech}, socket) do
    {:noreply,
      socket
      |> push_log("Technician #{tech.id} (#{tech.name}) added - status: #{tech.status}")
      |> refresh()}
  end

  def handle_info({:job_created, job}, socket) do
    {:noreply,
      socket
      |> push_log("Job created #{job.id} - #{job.title}")
      |> refresh()}
  end

  def handle_info({:job_unassigned, %{id: job_id}}, socket) do
    {:noreply,
      socket
      |> push_log("Job #{job_id} unassigned")
      |> refresh()}
  end

  def handle_info({:job_status_updated, job}, socket) do
    {:noreply,
      socket
      |> push_log("Job #{job.id} status -> #{job.status}")
      |> refresh()}
  end

  # Catch-all handler for any other messages to prevent crashes
  def handle_info(message, socket) do
    IO.inspect(message, label: "Unhandled message in AIAgentLive")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">AI Agent Dashboard</h1>
        <div class="space-x-2">
          <button phx-click="refresh" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            🔄 Refresh
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-2">System Status</h2>
          <div class="text-sm space-y-1">
            <div>Total Jobs: <%= length(@state.jobs) %></div>
            <div>Total Technicians: <%= length(@state.technicians) %></div>
            <div>Working Technicians: <%= length(@working_technicians) %></div>
            <div>Available Technicians: <%= length(@available_technicians) %></div>
          </div>
        </div>
        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-2">Smart Assignment</h2>
          <div class="space-x-2 text-sm">
            <button phx-click="auto_assign_all" class="px-3 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700">
              🤖 Autogentic: Auto Assign All Jobs
            </button>
          </div>
          <div class="text-xs text-gray-600 mt-2">
            Uses Autogentic to analyze skills, location, ratings & availability
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-3">Pending Jobs</h2>
          <ul class="space-y-2 text-sm">
            <%= for job <- @pending_jobs do %>
              <li class="flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= job.title %> (<%= job.id %>)</div>
                  <div class="text-gray-600">status: <%= job.status %> • company: <%= job.company_id %></div>
                </div>
              </li>
            <% end %>
            <%= if @pending_jobs == [] do %>
              <li class="text-gray-500">No pending jobs.</li>
            <% end %>
          </ul>
        </div>

        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-3">Active Jobs</h2>
          <ul class="space-y-2 text-sm">
            <%= for job <- @active_jobs do %>
              <li class="flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= job.title %> (<%= job.id %>)</div>
                  <div class="text-gray-600">status: <%= job.status %> • tech: <%= Map.get(job, :assigned_technician_id) %></div>
                </div>
              </li>
            <% end %>
            <%= if @active_jobs == [] do %>
              <li class="text-gray-500">No active jobs.</li>
            <% end %>
          </ul>
        </div>

        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-3">Completed Jobs</h2>
          <ul class="space-y-2 text-sm">
            <%= for job <- @completed_jobs do %>
              <li class="flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= job.title %> (<%= job.id %>)</div>
                  <div class="text-gray-600">status: <%= job.status %> • tech: <%= Map.get(job, :assigned_technician_id) %></div>
                </div>
              </li>
            <% end %>
            <%= if @completed_jobs == [] do %>
              <li class="text-gray-500">No completed jobs.</li>
            <% end %>
          </ul>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-3">🔧 Working Technicians</h2>
          <ul class="space-y-2 text-sm">
            <%= for tech <- @working_technicians do %>
              <li class="flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= tech.name %> (<%= tech.id %>)</div>
                  <div class="text-gray-600">status: <%= tech.status %> • rating: <%= tech.rating %> • skills: <%= Enum.join(tech.skills, ", ") %></div>
                </div>
              </li>
            <% end %>
            <%= if @working_technicians == [] do %>
              <li class="text-gray-500">No technicians currently working</li>
            <% end %>
          </ul>
        </div>

        <div class="p-4 border rounded">
          <h2 class="font-semibold mb-3">✅ Available Technicians</h2>
          <ul class="space-y-2 text-sm">
            <%= for tech <- @available_technicians do %>
              <li class="flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= tech.name %> (<%= tech.id %>)</div>
                  <div class="text-gray-600">status: <%= tech.status %> • rating: <%= tech.rating %> • skills: <%= Enum.join(tech.skills, ", ") %></div>
                </div>
              </li>
            <% end %>
            <%= if @available_technicians == [] do %>
              <li class="text-gray-500">All technicians are currently busy</li>
            <% end %>
          </ul>
        </div>
      </div>

      <div class="p-4 border rounded">
        <h2 class="font-semibold mb-3">📋 Activity Log</h2>
        <div class="space-y-1 text-sm max-h-64 overflow-y-auto">
          <%= for {ts, msg} <- @logs do %>
            <div class="text-gray-700">
              <span class="text-gray-500 text-xs"><%= ts %></span>
              <span class="ml-2"><%= msg %></span>
            </div>
          <% end %>
          <%= if @logs == [] do %>
            <div class="text-gray-500">No activity yet.</div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp refresh(socket) do
    state = ServiceWarp.GlobalState.get_state()
    stats = ServiceWarp.Agents.JobAssignmentAgent.get_stats()
        # Categorize jobs into three groups
        {pending, active_and_completed} = Enum.split_with(state.jobs, fn j ->
          # A job is pending if it has no assigned_technician_id AND is not completed
          Map.get(j, :assigned_technician_id) == nil and j.status != "completed"
        end)

        {active, completed} = Enum.split_with(active_and_completed, fn j ->
          # A job is active if it's assigned but not completed
          j.status != "completed"
        end)

    # Pull recent Autogentic logs from DB and merge into UI logs (dedup latest entries)
    db_logs = ServiceWarp.Repo.all(from(l in ServiceWarp.AutogenticLog, order_by: [desc: l.inserted_at], limit: 25))
    autogentic_entries = Enum.map(db_logs, fn l ->
      ts = NaiveDateTime.to_iso8601(l.inserted_at)
      {ts, "[autogentic] #{l.event} #{inspect(l.payload)}"}
    end)
    current_logs = socket.assigns[:logs] || []
    merged_logs = (autogentic_entries ++ current_logs) |> Enum.uniq() |> Enum.take(200)

    # Filter technicians like dashboard does
    working_technicians = state.technicians
    |> Enum.filter(& &1.status == "working")
    |> Enum.sort_by(& &1.rating, :desc)
    |> Enum.take(5)

    available_technicians = state.technicians
    |> Enum.filter(& &1.status == "available")
    |> Enum.sort_by(& &1.rating, :desc)
    |> Enum.take(5)

    socket
    |> assign(:state, state)
    |> assign(:stats, stats)
    |> assign(:pending_jobs, pending)
    |> assign(:active_jobs, active)
    |> assign(:completed_jobs, completed)
    |> assign(:working_technicians, working_technicians)
    |> assign(:available_technicians, available_technicians)
    |> assign(:logs, merged_logs)
  end

  defp push_log(socket, msg) do
    ts = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    update(socket, :logs, fn logs -> [{ts, msg} | logs] |> Enum.take(200) end)
  end

  # Smart assignment now delegated to ServiceWarp.AutogenticAdapter in auto_assign_all
end
