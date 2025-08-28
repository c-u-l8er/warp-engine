defmodule ServiceWarpWeb.TechniciansLive do
  use ServiceWarpWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 p-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Technicians Management</h1>
      <p class="text-gray-600">Technicians management interface coming soon...</p>
    </div>
    """
  end
end
