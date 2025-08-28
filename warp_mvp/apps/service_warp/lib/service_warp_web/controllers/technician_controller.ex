defmodule ServiceWarpWeb.TechnicianController do
  use ServiceWarpWeb, :controller

  def index(conn, _params) do
    # Get all technicians for the company (for now, hardcoded demo company)
    company_id = "demo_company_123"
    technicians = ServiceWarp.GlobalState.get_company_technicians(company_id)

    json(conn, %{technicians: technicians})
  end

  def create(conn, params) do
    # Create a new technician
    technician = ServiceWarp.Technicians.Technician.new(params)

    case ServiceWarp.GlobalState.add_technician(technician) do
      {:ok, created_technician} ->
        conn
        |> put_status(:created)
        |> json(%{technician: created_technician})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def show(conn, %{"id" => tech_id}) do
    # Get a specific technician
    company_id = "demo_company_123"
    technicians = ServiceWarp.GlobalState.get_company_technicians(company_id)

    case Enum.find(technicians, &(&1.id == tech_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Technician not found"})

      technician ->
        json(conn, %{technician: technician})
    end
  end

  def update(conn, %{"id" => tech_id} = params) do
    # Update a technician
    company_id = "demo_company_123"
    technicians = ServiceWarp.GlobalState.get_company_technicians(company_id)

    case Enum.find(technicians, &(&1.id == tech_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Technician not found"})

      technician ->
        # For now, just return the technician as-is
        # In a real implementation, you'd update the technician in the database
        updated_technician = Map.merge(technician, params)

        json(conn, %{technician: updated_technician})
    end
  end

  def delete(conn, %{"id" => tech_id}) do
    # Delete a technician
    # For now, just return success
    # In a real implementation, you'd delete the technician from the database

    json(conn, %{message: "Technician deleted successfully"})
  end

  def update_location(conn, %{"id" => tech_id, "coordinates" => coordinates}) do
    # Update technician location
    case ServiceWarp.GlobalState.update_technician_location(tech_id, coordinates) do
      {:ok, updated_technician} ->
        json(conn, %{technician: updated_technician})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end
end
