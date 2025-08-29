defmodule ServiceWarp.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      @primary_key {:id, :string, autogenerate: false}
      @foreign_key_type :string
      @timestamps_opts [type: :utc_datetime]
    end
  end
end

defmodule ServiceWarp.Companies.Company do
  use ServiceWarp.Schema

  schema "companies" do
    field :name, :string
    field :industry, :string
    field :coordinates, {:array, :float}
    field :subscription_plan, :string
    field :technician_limit, :integer
    field :active_technicians, :integer
    field :billing_status, :string
    field :settings, :map

    has_many :technicians, ServiceWarp.Technicians.Technician
    has_many :jobs, ServiceWarp.Jobs.Job

    timestamps()
  end

  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :industry, :coordinates, :subscription_plan, :technician_limit, :active_technicians, :billing_status, :settings])
    |> validate_required([:name, :industry, :coordinates])
    |> validate_coordinates()
  end

  defp validate_coordinates(changeset) do
    case get_change(changeset, :coordinates) do
      nil -> changeset
      coords when is_list(coords) and length(coords) == 2 ->
        [lat, lng] = coords
        if is_number(lat) and is_number(lng) and lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180 do
          changeset
        else
          add_error(changeset, :coordinates, "Invalid coordinates")
        end
      _ -> add_error(changeset, :coordinates, "Coordinates must be [lat, lng]")
    end
  end
end

defmodule ServiceWarp.Technicians.Technician do
  use ServiceWarp.Schema

  schema "technicians" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :coordinates, {:array, :float}
    field :skills, {:array, :string}
    field :status, :string
    field :current_job_id, :string
    field :rating, :float
    field :experience_level, :string

    belongs_to :company, ServiceWarp.Companies.Company
    has_many :assigned_jobs, ServiceWarp.Jobs.Job, foreign_key: :assigned_technician_id

    timestamps()
  end

  def changeset(technician, attrs) do
    technician
    |> cast(attrs, [:name, :email, :phone, :coordinates, :skills, :status, :current_job_id, :rating, :experience_level, :company_id])
    |> validate_required([:name, :email, :coordinates, :skills, :status])
    |> validate_coordinates()
    |> validate_rating()
    |> foreign_key_constraint(:company_id)
  end

  defp validate_coordinates(changeset) do
    case get_change(changeset, :coordinates) do
      nil -> changeset
      coords when is_list(coords) and length(coords) == 2 ->
        [lat, lng] = coords
        if is_number(lat) and is_number(lng) and lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180 do
          changeset
        else
          add_error(changeset, :coordinates, "Invalid coordinates")
        end
      _ -> add_error(changeset, :coordinates, "Coordinates must be [lat, lng]")
    end
  end

  defp validate_rating(changeset) do
    case get_change(changeset, :rating) do
      nil -> changeset
      rating when is_number(rating) and rating >= 0 and rating <= 5 ->
        changeset
      _ -> add_error(changeset, :rating, "Rating must be between 0 and 5")
    end
  end
end

defmodule ServiceWarp.Jobs.Job do
  use ServiceWarp.Schema

  schema "jobs" do
    field :title, :string
    field :description, :string
    field :coordinates, {:array, :float}
    field :address, :string
    field :required_skills, {:array, :string}
    field :status, :string
    field :priority, :string
    field :customer_name, :string
    field :estimated_duration, :integer

    belongs_to :company, ServiceWarp.Companies.Company
    belongs_to :assigned_technician, ServiceWarp.Technicians.Technician, foreign_key: :assigned_technician_id

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:title, :description, :coordinates, :address, :required_skills, :status, :priority, :customer_name, :estimated_duration, :company_id, :assigned_technician_id])
    |> validate_required([:title, :description, :coordinates, :required_skills, :status, :priority])
    |> validate_coordinates()
    |> validate_duration()
    |> foreign_key_constraint(:company_id)
    |> foreign_key_constraint(:assigned_technician_id)
  end

  defp validate_coordinates(changeset) do
    case get_change(changeset, :coordinates) do
      nil -> changeset
      coords when is_list(coords) and length(coords) == 2 ->
        [lat, lng] = coords
        if is_number(lat) and is_number(lng) and lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180 do
          changeset
        else
          add_error(changeset, :coordinates, "Invalid coordinates")
        end
      _ -> add_error(changeset, :coordinates, "Coordinates must be [lat, lng]")
    end
  end

  defp validate_duration(changeset) do
    case get_change(changeset, :estimated_duration) do
      nil -> changeset
      duration when is_integer(duration) and duration > 0 ->
        changeset
      _ -> add_error(changeset, :estimated_duration, "Duration must be positive integer")
    end
  end
end
