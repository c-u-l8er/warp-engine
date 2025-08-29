defmodule ServiceWarp.Technicians.Technician do
  @moduledoc """
  Technician management for ServiceWarp.
  """

  defstruct [
    :id,
    :name,
    :email,
    :phone,
    :coordinates,
    :skills,
    :status,
    :current_job_id,
    :company_id,
    :rating,
    :experience_level,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new technician with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      name: attrs[:name] || "New Technician",
      email: attrs[:email] || "tech@example.com",
      phone: attrs[:phone] || "(555) 000-0000",
      coordinates: attrs[:coordinates] || {0.0, 0.0},
      skills: attrs[:skills] || [],
      status: attrs[:status] || "available",
      current_job_id: attrs[:current_job_id],
      company_id: attrs[:company_id] || "default_company",
      rating: attrs[:rating] || 4.5,
      experience_level: attrs[:experience_level] || "intermediate",
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the location of a technician.
  """
  def update_location(technician, coordinates) do
    %{technician | coordinates: coordinates, updated_at: DateTime.utc_now()}
  end

  @doc """
  Updates the status of a technician.
  """
  def update_status(technician, new_status) do
    %{technician | status: new_status, updated_at: DateTime.utc_now()}
  end

  @doc """
  Assigns a job to a technician.
  """
  def assign_job(technician, job_id) do
    %{technician |
      current_job_id: job_id,
      status: "working",
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Completes a job for a technician.
  """
  def complete_job(technician, _job_id) do
    %{technician |
      current_job_id: nil,
      status: "available",
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if a technician has specific skills.
  """
  def has_skills?(technician, skills) do
    Enum.all?(skills, &(&1 in technician.skills))
  end

  @doc """
  Checks if a technician is available.
  """
  def available?(technician) do
    technician.status == "available"
  end

  @doc """
  Checks if a technician is working.
  """
  def working?(technician) do
    technician.status == "working"
  end

  @doc """
  Gets the location of a technician.
  """
  def location(technician) do
    technician.coordinates
  end

  # Private functions

  defp generate_id do
    "tech_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
