defmodule ServiceWarp.Jobs.Job do
  @moduledoc """
  Represents a service job in the system.

  Each job has spatial coordinates, requirements, and status tracking.
  """

  defstruct [
    :id,
    :title,
    :description,
    :coordinates,           # {lat, lon}
    :address,
    :required_skills,       # List of skill IDs
    :priority,              # :low, :normal, :high, :urgent
    :status,                # :pending, :assigned, :in_progress, :completed, :cancelled
    :assigned_technician_id,
    :customer_id,
    :company_id,            # Multi-tenant support
    :scheduled_time,
    :estimated_duration,    # minutes
    :actual_duration,       # minutes
    :customer_notes,
    :internal_notes,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    title: String.t(),
    description: String.t(),
    coordinates: {float(), float()},
    address: String.t(),
    required_skills: [String.t()],
    priority: :low | :normal | :high | :urgent,
    status: :pending | :assigned | :in_progress | :completed | :cancelled,
    assigned_technician_id: String.t() | nil,
    customer_id: String.t(),
    company_id: String.t(),
    scheduled_time: DateTime.t() | nil,
    estimated_duration: non_neg_integer(),
    actual_duration: non_neg_integer() | nil,
    customer_notes: String.t() | nil,
    internal_notes: String.t() | nil,
    created_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  @doc """
  Creates a new job with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      title: "",
      description: "",
      coordinates: {0.0, 0.0},
      address: "",
      required_skills: [],
      priority: :normal,
      status: :pending,
      assigned_technician_id: nil,
      customer_id: "",
      company_id: "",
      scheduled_time: nil,
      estimated_duration: 60,
      actual_duration: nil,
      customer_notes: nil,
      internal_notes: nil,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    |> Map.merge(attrs)
  end

  @doc """
  Updates the job status and sets updated_at timestamp.
  """
  def update_status(job, new_status) do
    %{job |
      status: new_status,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Assigns a technician to the job.
  """
  def assign_technician(job, technician_id) do
    %{job |
      assigned_technician_id: technician_id,
      status: :assigned,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if the job is urgent based on priority and status.
  """
  def urgent?(job) do
    job.priority == :urgent or
    (job.priority == :high and job.status == :pending)
  end

  @doc """
  Gets the job location as coordinates for spatial operations.
  """
  def location(job) do
    job.coordinates
  end

  @doc """
  Checks if the job requires specific skills.
  """
  def requires_skills?(job, skills) do
    Enum.any?(skills, &(&1 in job.required_skills))
  end

  defp generate_id do
    "job_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
