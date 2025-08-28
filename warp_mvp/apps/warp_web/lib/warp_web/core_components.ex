defmodule WarpWeb.CoreComponents do
  @moduledoc """
  Provides core UI components and functionality for WarpWeb.
  """
  use Phoenix.Component

  # Import core components from Phoenix
  # These imports are available for future use

  # Core component functions
  def icon(assigns) do
    ~H"""
    <span class="icon">
      <%= @name %>
    </span>
    """
  end

  def button(assigns) do
    ~H"""
    <button class="button" type={@type || "button"}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def card(assigns) do
    ~H"""
    <div class="card">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
