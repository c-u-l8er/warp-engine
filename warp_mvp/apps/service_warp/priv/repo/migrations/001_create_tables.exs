defmodule ServiceWarp.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    # Enable PostGIS extension for spatial operations
    execute "CREATE EXTENSION IF NOT EXISTS postgis", ""

    # Companies table
    create table(:companies, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :industry, :string, null: false
      add :coordinates, :point, null: false
      add :subscription_plan, :string, default: "Starter"
      add :technician_limit, :integer, default: 10
      add :active_technicians, :integer, default: 0
      add :billing_status, :string, default: "active"
      add :settings, :map, default: %{}

      timestamps()
    end

    # Create spatial index on company coordinates
    execute "CREATE INDEX companies_coordinates_idx ON companies USING GIST (coordinates)", ""

    # Technicians table
    create table(:technicians, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :coordinates, :point, null: false
      add :skills, {:array, :string}, default: []
      add :status, :string, default: "available"
      add :current_job_id, :string
      add :rating, :float, default: 4.5
      add :experience_level, :string, default: "intermediate"
      add :company_id, references(:companies, type: :string, on_delete: :delete_all), null: false

      timestamps()
    end

    # Create spatial index on technician coordinates
    execute "CREATE INDEX technicians_coordinates_idx ON technicians USING GIST (coordinates)", ""
    # Create index on company_id for fast lookups
    create index(:technicians, [:company_id])
    # Create index on status for filtering
    create index(:technicians, [:status])

    # Jobs table
    create table(:jobs, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :coordinates, :point, null: false
      add :address, :string
      add :required_skills, {:array, :string}, default: []
      add :status, :string, default: "pending"
      add :priority, :string, default: "medium"
      add :customer_name, :string
      add :estimated_duration, :integer
      add :company_id, references(:companies, type: :string, on_delete: :delete_all), null: false
      add :assigned_technician_id, references(:technicians, type: :string, on_delete: :nilify_all)

      timestamps()
    end

    # Create spatial index on job coordinates
    execute "CREATE INDEX jobs_coordinates_idx ON jobs USING GIST (coordinates)", ""
    # Create index on company_id for fast lookups
    create index(:jobs, [:company_id])
    # Create index on status for filtering
    create index(:jobs, [:status])
    # Create index on priority for sorting
    create index(:jobs, [:priority])
    # Create index on assigned_technician_id for job assignments
    create index(:jobs, [:assigned_technician_id])

    # Create spatial functions for distance calculations
    execute """
    CREATE OR REPLACE FUNCTION calculate_distance(point1 point, point2 point)
    RETURNS float AS $$
    BEGIN
      RETURN ST_Distance(
        ST_SetSRID(point1, 4326)::geography,
        ST_SetSRID(point2, 4326)::geography
      );
    END;
    $$ LANGUAGE plpgsql;
    """, ""

    # Create function to find technicians within radius
    execute """
    CREATE OR REPLACE FUNCTION find_technicians_in_radius(
      center_point point,
      radius_meters float,
      required_skills text[] DEFAULT NULL,
      company_id text DEFAULT NULL
    )
    RETURNS TABLE(
      id text,
      name text,
      email text,
      phone text,
      coordinates point,
      skills text[],
      status text,
      rating float,
      experience_level text,
      distance float
    ) AS $$
    BEGIN
      RETURN QUERY
      SELECT
        t.id,
        t.name,
        t.email,
        t.phone,
        t.coordinates,
        t.skills,
        t.status,
        t.rating,
        t.experience_level,
        calculate_distance(center_point, t.coordinates) as distance
      FROM technicians t
      WHERE
        calculate_distance(center_point, t.coordinates) <= radius_meters
        AND (required_skills IS NULL OR t.skills && required_skills)
        AND (company_id IS NULL OR t.company_id = company_id)
        AND t.status = 'available'
      ORDER BY distance ASC;
    END;
    $$ LANGUAGE plpgsql;
    """, ""
  end

  def down do
    # Drop functions first
    execute "DROP FUNCTION IF EXISTS find_technicians_in_radius(point, float, text[], text)", ""
    execute "DROP FUNCTION IF EXISTS calculate_distance(point, point)", ""

    # Drop tables (order matters due to foreign keys)
    drop table(:jobs)
    drop table(:technicians)
    drop table(:companies)

    # Drop PostGIS extension
    execute "DROP EXTENSION IF EXISTS postgis", ""
  end
end
