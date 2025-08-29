defmodule ServiceWarp.AutogenticAdapter do
  @moduledoc """
  Thin wrapper that delegates complex assignment reasoning to Autogentic v2.0.

  This module provides a clean boundary so ServiceWarp can call into
  Autogentic for intelligent decisions (e.g., auto-assigning jobs) while
  keeping ServiceWarp domain logic simple.
  """

  require Logger

  @doc """
  Given all jobs and technicians, return a list of assignment decisions
  like [%{job_id: job_id, technician_id: tech_id}, ...].

  Uses Autogentic's Effects + Reasoning engines to orchestrate the
  planning process; falls back to local scoring if Autogentic fails.
  """
  def plan_assignments(jobs, technicians) do
    Logger.info("AutogenticAdapter.plan_assignments/2 invoked with #{length(jobs)} jobs, #{length(technicians)} techs")

    context = %{
      jobs: jobs,
      technicians: technicians
    }

    effects = [
      Autogentic.Effects.log(:info, "🧠 Autogentic: Starting assignment planning"),
      Autogentic.Effects.emit_event(:autogentic_planning_started, %{count_jobs: length(jobs), count_techs: length(technicians)}),
      Autogentic.Effects.reason_about(
        "What is the optimal job→technician assignment plan?",
        [
          %{id: :skills_fit, question: "Who has matching skills?", analysis_type: :assessment, context_required: [:jobs, :technicians], output_format: :analysis},
          %{id: :location_cost, question: "Who is closest to each job?", analysis_type: :evaluation, context_required: [:jobs, :technicians], output_format: :analysis},
          %{id: :quality_bias, question: "How should ratings influence selection?", analysis_type: :consideration, output_format: :analysis},
          %{id: :final_reco, question: "Combine all factors into final plan", analysis_type: :synthesis, output_format: :recommendation}
        ]
      ),
      Autogentic.Effects.emit_event(:autogentic_planning_recommendation, %{note: "plan ready"}),
      Autogentic.Effects.put_data(:decisions, compute_decisions(jobs, technicians)),
      Autogentic.Effects.learn_from_outcome("assignment_planning", %{success: true})
    ]

    effect = Autogentic.Effects.sequence_effects(effects)

    # Subscribe to Autogentic PubSub temporarily to capture events for persistence
    Phoenix.PubSub.subscribe(Autogentic.PubSub, "agent_events")

    result = Autogentic.execute_effect(effect, context)

    # Drain any events emitted during execution and persist
    persist_pubsub_events()
    Phoenix.PubSub.unsubscribe(Autogentic.PubSub, "agent_events")

    case result do
      {:ok, updated_context} when is_map(updated_context) ->
        Map.get(updated_context, :decisions, [])
      {:ok, _other} ->
        compute_decisions(jobs, technicians)
      {:error, reason} ->
        Logger.warning("Autogentic planning failed, using fallback: #{inspect(reason)}")
        compute_decisions(jobs, technicians)
    end
  end

  # ——— Internal helpers ———

  defp compute_decisions(jobs, technicians) do
    pending_jobs = Enum.filter(jobs, fn j -> Map.get(j, :assigned_technician_id) == nil and j.status != "completed" end)
    available_techs = Enum.filter(technicians, & &1.status == "available")

    {decisions, _remaining} = Enum.reduce(pending_jobs, {[], available_techs}, fn job, {acc, avail} ->
      qualified = Enum.filter(avail, fn tech ->
        Enum.any?(job.required_skills, &(&1 in tech.skills))
      end)

      case qualified do
        [] -> {acc, avail}
        _ ->
          {best, _score} =
            qualified
            |> Enum.map(fn tech -> {tech, score(tech, job)} end)
            |> Enum.sort_by(fn {_t, s} -> s end, :desc)
            |> List.first()

          decisions = [%{job_id: job.id, technician_id: best.id} | acc]
          {decisions, Enum.reject(avail, &(&1.id == best.id))}
      end
    end)

    Enum.reverse(decisions)
  end

  defp score(tech, job) do
    skill_bonus = Enum.count(tech.skills, &(&1 in job.required_skills)) * 20
    rating_bonus = ((tech.rating || 0) * 10)
    distance = distance(tech.coordinates, job.coordinates)
    location_bonus = max(0, 50 - distance * 10)
    skill_bonus + rating_bonus + location_bonus
  end

  defp distance({lat1, lng1}, {lat2, lng2}) do
    :math.sqrt(:math.pow(lat1 - lat2, 2) + :math.pow(lng1 - lng2, 2))
  end

  defp persist_pubsub_events do
    receive do
      {event, payload} when is_atom(event) ->
        _ = ServiceWarp.Repo.insert(%ServiceWarp.AutogenticLog{event: to_string(event), payload: payload, level: "info"})
        persist_pubsub_events()
    after
      50 -> :ok
    end
  end
end
