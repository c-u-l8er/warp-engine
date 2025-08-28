defmodule ServiceWarpWeb.JobController do
  use ServiceWarpWeb, :controller

  def index(conn, _params) do
    # Get all jobs for the company (for now, hardcoded demo company)
    company_id = "demo_company_123"
    jobs = ServiceWarp.GlobalState.get_company_jobs(company_id)

    json(conn, %{jobs: jobs})
  end

  def create(conn, params) do
    # Create a new job
    job = ServiceWarp.Jobs.Job.new(params)

    case ServiceWarp.GlobalState.add_job(job) do
      {:ok, created_job} ->
        conn
        |> put_status(:created)
        |> json(%{job: created_job})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def show(conn, %{"id" => job_id}) do
    # Get a specific job
    company_id = "demo_company_123"
    jobs = ServiceWarp.GlobalState.get_company_jobs(company_id)

    case Enum.find(jobs, &(&1.id == job_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Job not found"})

      job ->
        json(conn, %{job: job})
    end
  end

  def update(conn, %{"id" => job_id} = params) do
    # Update a job
    company_id = "demo_company_123"
    jobs = ServiceWarp.GlobalState.get_company_jobs(company_id)

    case Enum.find(jobs, &(&1.id == job_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Job not found"})

      job ->
        # For now, just return the job as-is
        # In a real implementation, you'd update the job in the database
        updated_job = Map.merge(job, params)

        json(conn, %{job: updated_job})
    end
  end

  def delete(conn, %{"id" => job_id}) do
    # Delete a job
    # For now, just return success
    # In a real implementation, you'd delete the job from the database

    json(conn, %{message: "Job deleted successfully"})
  end
end
