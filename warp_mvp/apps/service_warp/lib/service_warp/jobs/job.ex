defmodule ServiceWarp.Jobs.Job do
  @moduledoc """
  Job management for ServiceWarp.
  """

  defstruct [
    :id,
    :title,
    :description,
    :coordinates,
    :address,
    :required_skills,
    :status,
    :priority,
    :customer_name,
    :estimated_duration,
    :assigned_technician_id,
    :company_id,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new job with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      title: attrs[:title] || "New Job",
      description: attrs[:description] || "Job description",
      coordinates: attrs[:coordinates] || {0.0, 0.0},
      address: attrs[:address] || "Address not specified",
      required_skills: attrs[:required_skills] || [],
      status: attrs[:status] || "pending",
      priority: attrs[:priority] || "medium",
      customer_name: attrs[:customer_name] || "Customer",
      estimated_duration: attrs[:estimated_duration] || 60,
      assigned_technician_id: attrs[:assigned_technician_id],
      company_id: attrs[:company_id] || "default_company",
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the status of a job.
  """
  def update_status(job, new_status) do
    %{job | status: new_status, updated_at: DateTime.utc_now()}
  end

  @doc """
  Assigns a technician to a job.
  """
  def assign_technician(job, technician_id) do
    %{job |
      assigned_technician_id: technician_id,
      status: "assigned",
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if a job is urgent.
  """
  def urgent?(job) do
    job.status == "urgent" or job.priority == "high"
  end

  @doc """
  Gets the location of a job.
  """
  def location(job) do
    job.coordinates
  end

  @doc """
  Checks if a job requires specific skills.
  """
  def requires_skills?(job, skills) do
    Enum.all?(skills, &(&1 in job.required_skills))
  end

  # Private functions

  defp generate_id do
    "job_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
