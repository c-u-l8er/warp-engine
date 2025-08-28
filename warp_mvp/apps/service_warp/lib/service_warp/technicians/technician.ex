defmodule ServiceWarp.Technicians.Technician do
  @moduledoc """
  Represents a field service technician in the system.

  Each technician has skills, current location, and availability status.
  """

  defstruct [
    :id,
    :name,
    :email,
    :phone,
    :coordinates,           # {lat, lon} - current location
    :skills,                # List of skill IDs
    :experience_level,      # :junior, :intermediate, :senior, :expert
    :status,                # :available, :busy, :off_duty, :on_break
    :current_job_id,        # Currently assigned job
    :company_id,            # Multi-tenant support
    :vehicle_info,          # Vehicle details for routing
    :working_hours,         # Available working hours
    :rating,                # Customer rating (1.0 - 5.0)
    :total_jobs_completed,
    :created_at,
    :updated_at,
    :last_location_update   # When location was last updated
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    name: String.t(),
    email: String.t(),
    phone: String.t(),
    coordinates: {float(), float()},
    skills: [String.t()],
    experience_level: :junior | :intermediate | :senior | :expert,
    status: :available | :busy | :off_duty | :on_break,
    current_job_id: String.t() | nil,
    company_id: String.t(),
    vehicle_info: map() | nil,
    working_hours: map() | nil,
    rating: float() | nil,
    total_jobs_completed: non_neg_integer(),
    created_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil,
    last_location_update: DateTime.t() | nil
  }

  @doc """
  Creates a new technician with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      name: "",
      email: "",
      phone: "",
      coordinates: {0.0, 0.0},
      skills: [],
      experience_level: :intermediate,
      status: :available,
      current_job_id: nil,
      company_id: "",
      vehicle_info: nil,
      working_hours: %{
        monday: {8, 17},    # {start_hour, end_hour}
        tuesday: {8, 17},
        wednesday: {8, 17},
        thursday: {8, 17},
        friday: {8, 17},
        saturday: {9, 15},
        sunday: {10, 14}
      },
      rating: nil,
      total_jobs_completed: 0,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      last_location_update: DateTime.utc_now()
    }
    |> Map.merge(attrs)
  end

  @doc """
  Updates the technician's current location.
  """
  def update_location(technician, new_coordinates) do
    %{technician |
      coordinates: new_coordinates,
      last_location_update: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the technician's status.
  """
  def update_status(technician, new_status) do
    %{technician |
      status: new_status,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Assigns a job to the technician.
  """
  def assign_job(technician, job_id) do
    %{technician |
      current_job_id: job_id,
      status: :busy,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Completes a job and updates stats.
  """
  def complete_job(technician, rating) do
    new_rating = calculate_new_rating(technician.rating, rating, technician.total_jobs_completed)

    %{technician |
      current_job_id: nil,
      status: :available,
      rating: new_rating,
      total_jobs_completed: technician.total_jobs_completed + 1,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if the technician has the required skills.
  """
  def has_skills?(technician, required_skills) do
    Enum.all?(required_skills, &(&1 in technician.skills))
  end

  @doc """
  Checks if the technician is available for new jobs.
  """
  def available?(technician) do
    technician.status == :available and
    is_nil(technician.current_job_id)
  end

  @doc """
  Gets the technician's current location for spatial operations.
  """
  def location(technician) do
    technician.coordinates
  end

  @doc """
  Checks if the technician is currently working.
  """
  def working?(technician) do
    technician.status == :busy and not is_nil(technician.current_job_id)
  end

  defp calculate_new_rating(current_rating, new_rating, total_jobs) do
    if is_nil(current_rating) do
      new_rating
    else
      ((current_rating * total_jobs) + new_rating) / (total_jobs + 1)
    end
  end

  defp generate_id do
    "tech_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
