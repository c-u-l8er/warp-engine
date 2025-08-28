#!/usr/bin/env elixir

# Heavy Enhanced ADT Weighted Graph Database Benchmark (no WarpEngine deps)
# - Uses SimpleWeightedGraph (examples/simple_weighted_graph.ex)
# - Warmups + multiple measured runs
# - Larger datasets and repeated validation passes
# - Monotonic timing and robust statistics
# - Optional parallel processing (BENCH_PARALLEL=1, BENCH_MAX_CONC=N)

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

defmodule HeavyADTBench do
  @moduledoc false

  def env_int(var, default) do
    case System.get_env(var) do
      nil -> default
      val ->
        case Integer.parse(val) do
          {i, _} -> i
          :error -> default
        end
    end
  end

  def env_bool(var, default) do
    case System.get_env(var) do
      nil -> default
      val ->
        case String.downcase(to_string(val)) do
          "1" -> true
          "true" -> true
          "yes" -> true
          "on" -> true
          _ -> false
        end
    end
  end

  def ceil_div(a, b), do: div(a + b - 1, b)

  def now_ns, do: System.monotonic_time(:nanosecond)

  def measure_ms(fun) when is_function(fun, 0) do
    t0 = now_ns()
    result = fun.()
    dt_ms = (now_ns() - t0) / 1_000_000
    {dt_ms, result}
  end

  def stats_ms(samples) when is_list(samples) and samples != [] do
    sorted = Enum.sort(samples)
    n = length(sorted)
    avg = Enum.sum(sorted) / n
    p50 = percentile(sorted, 50)
    p95 = percentile(sorted, 95)
    %{min: hd(sorted), p50: p50, avg: avg, p95: p95, max: List.last(sorted)}
  end

  defp percentile(sorted, p) do
    idx = max(0, min(length(sorted) - 1, round((p / 100) * (length(sorted) - 1))))
    Enum.at(sorted, idx)
  end

  def run do
    Logger.info("🚀 Heavy Enhanced ADT Benchmark starting...")

    # Parameters (overridable via env)
    nodes_count   = env_int("BENCH_NODES", 10_000)
    edges_count   = env_int("BENCH_EDGES", 20_000)
    warmups       = env_int("BENCH_WARMUP", 2)
    runs          = env_int("BENCH_RUNS", 5)
    repeat_factor = env_int("BENCH_REPEAT", 5)
    par_enabled   = env_bool("BENCH_PARALLEL", false)
    max_conc      = env_int("BENCH_MAX_CONC", :erlang.system_info(:schedulers_online))

    Logger.info("⚙️  Config: nodes=#{nodes_count}, edges=#{edges_count}, warmup=#{warmups}, runs=#{runs}, repeat=#{repeat_factor}, parallel=#{par_enabled}, max_conc=#{max_conc}")
    Logger.info("🧪 Compiling simplified ADT module...")
    Code.compile_file("examples/simple_weighted_graph.ex")
    Logger.info("✅ Simplified ADT ready")

    # Pre-generate data outside timed sections
    Logger.info("📦 Generating datasets...")
    {gen_nodes_ms, nodes} = measure_ms(fn ->
      Enum.map(1..nodes_count, fn i ->
        SimpleWeightedGraph.new_node(
          "node_#{i}",
          "Node #{i}",
          %{bench: true, idx: i, attr: :erlang.phash2(i, 10)},
          :rand.uniform(),
          :rand.uniform(),
          DateTime.utc_now(),
          :bench
        )
      end)
    end)

    node_ids = Enum.map(nodes, & &1.id)

    {gen_edges_ms, edges} = measure_ms(fn ->
      Enum.map(1..edges_count, fn i ->
        # Connect sequentially with wrap-around
        from = Enum.at(node_ids, rem(i - 1, nodes_count))
        to   = Enum.at(node_ids, rem(i, nodes_count))
        SimpleWeightedGraph.new_edge(
          "edge_#{i}",
          from,
          to,
          :rand.uniform(),
          :rand.uniform(),
          :bench_rel,
          %{w: :rand.uniform()},
          DateTime.utc_now(),
          :rand.uniform()
        )
      end)
    end)

    Logger.info("📦 Data ready: gen_nodes=#{Float.round(gen_nodes_ms, 1)}ms, gen_edges=#{Float.round(gen_edges_ms, 1)}ms")

    # Helpers for sequential validations
    node_reduce_seq = fn ->
      Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
        {sum, _hist} =
          Enum.reduce(nodes, {0.0, %{}}, fn n, {s, hist} ->
            # Validate
            if is_nil(n.id) or is_nil(n.label) or is_nil(n.properties) do
              raise "Invalid node: #{inspect(n)}"
            end
            if n.importance_score < 0.0 or n.importance_score > 1.0, do: raise("bad importance")
            if n.activity_level < 0.0 or n.activity_level > 1.0, do: raise("bad activity")

            derived = n.importance_score * n.activity_level
            bucket = trunc(derived * 10)
            hist2 = Map.update(hist, bucket, 1, &(&1 + 1))
            {s + derived, hist2}
          end)
        acc + sum
      end)
    end

    edge_reduce_seq = fn ->
      Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
        total =
          Enum.reduce(edges, 0.0, fn e, s ->
            if is_nil(e.id) or is_nil(e.from_node) or is_nil(e.to_node) do
              raise "Invalid edge: #{inspect(e)}"
            end
            if e.weight < 0.0 or e.weight > 1.0, do: raise("bad weight")
            if e.frequency < 0.0 or e.frequency > 1.0, do: raise("bad frequency")
            s + e.weight * e.frequency
          end)
        acc + total
      end)
    end

    # Parallel versions (chunk + async_stream)
    node_reduce_par = fn ->
      chunk_size = max(1, ceil_div(length(nodes), max_conc))
      Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
        partials =
          Task.async_stream(
            Stream.chunk_every(nodes, chunk_size),
            fn chunk ->
              Enum.reduce(chunk, {0.0, %{}}, fn n, {s, hist} ->
                if is_nil(n.id) or is_nil(n.label) or is_nil(n.properties), do: raise("Invalid node")
                if n.importance_score < 0.0 or n.importance_score > 1.0, do: raise("bad importance")
                if n.activity_level < 0.0 or n.activity_level > 1.0, do: raise("bad activity")
                derived = n.importance_score * n.activity_level
                bucket = trunc(derived * 10)
                hist2 = Map.update(hist, bucket, 1, &(&1 + 1))
                {s + derived, hist2}
              end)
            end,
            max_concurrency: max_conc,
            ordered: false
          )
          |> Enum.map(fn {:ok, {sum, _hist}} -> sum end)

        acc + Enum.sum(partials)
      end)
    end

    edge_reduce_par = fn ->
      chunk_size = max(1, ceil_div(length(edges), max_conc))
      Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
        partials =
          Task.async_stream(
            Stream.chunk_every(edges, chunk_size),
            fn chunk ->
              Enum.reduce(chunk, 0.0, fn e, s ->
                if is_nil(e.id) or is_nil(e.from_node) or is_nil(e.to_node), do: raise("Invalid edge")
                if e.weight < 0.0 or e.weight > 1.0, do: raise("bad weight")
                if e.frequency < 0.0 or e.frequency > 1.0, do: raise("bad frequency")
                s + e.weight * e.frequency
              end)
            end,
            max_concurrency: max_conc,
            ordered: false
          )
          |> Enum.map(fn {:ok, sum} -> sum end)

        acc + Enum.sum(partials)
      end)
    end

    build_graph_seq = fn ->
      {adj, _} =
        Enum.reduce(edges, {%{}, %{}}, fn e, {adj, deg} ->
          adj2 = Map.update(adj, e.from_node, [e.to_node], &[e.to_node | &1])
          deg2 = Map.update(deg, e.from_node, 1, &(&1 + 1))
          {adj2, deg2}
        end)

      _top5 =
        adj
        |> Enum.map(fn {k, vs} -> {k, length(vs)} end)
        |> Enum.sort_by(fn {_k, d} -> -d end)
        |> Enum.take(5)
      :ok
    end

    build_graph_par = fn ->
      chunk_size = max(1, ceil_div(length(edges), max_conc))

      partials =
        Task.async_stream(
          Stream.chunk_every(edges, chunk_size),
          fn chunk ->
            Enum.reduce(chunk, {%{}, %{}}, fn e, {adj, deg} ->
              adj2 = Map.update(adj, e.from_node, [e.to_node], &[e.to_node | &1])
              deg2 = Map.update(deg, e.from_node, 1, &(&1 + 1))
              {adj2, deg2}
            end)
          end,
          max_concurrency: max_conc,
          ordered: false
        )
        |> Enum.map(fn {:ok, maps} -> maps end)

      {adj, _deg} =
        Enum.reduce(partials, {%{}, %{}}, fn {a, d}, {acc_a, acc_d} ->
          acc_a2 = Map.merge(acc_a, a, fn _k, v1, v2 -> v1 ++ v2 end)
          acc_d2 = Map.merge(acc_d, d, fn _k, v1, v2 -> v1 + v2 end)
          {acc_a2, acc_d2}
        end)

      _top5 =
        adj
        |> Enum.map(fn {k, vs} -> {k, length(vs)} end)
        |> Enum.sort_by(fn {_k, d} -> -d end)
        |> Enum.take(5)
      :ok
    end

    node_pass = if par_enabled, do: node_reduce_par, else: node_reduce_seq
    edge_pass = if par_enabled, do: edge_reduce_par, else: edge_reduce_seq
    build_graph = if par_enabled, do: build_graph_par, else: build_graph_seq

    # Warmups
    Logger.info("🔥 Warmup runs: #{warmups}")
    Enum.each(1..warmups, fn i ->
      :erlang.garbage_collect()
      {_t1, _} = measure_ms(node_pass)
      {_t2, _} = measure_ms(edge_pass)
      {_t3, _} = measure_ms(build_graph)
      Logger.info("  • warmup #{i} done")
    end)

    # Measured runs
    node_times = []
    edge_times = []
    graph_times = []

    Logger.info("🏁 Measured runs: #{runs}")
    {all_ms, {node_times, edge_times, graph_times}} = measure_ms(fn ->
      Enum.reduce(1..runs, {[], [], []}, fn i, {nt, et, gt} ->
        :erlang.garbage_collect()
        {tn, _} = measure_ms(node_pass)
        {te, _} = measure_ms(edge_pass)
        {tg, _} = measure_ms(build_graph)
        Logger.info("  • run #{i}: nodes=#{Float.round(tn, 1)}ms edges=#{Float.round(te, 1)}ms graph=#{Float.round(tg, 1)}ms")
        {[tn | nt], [te | et], [tg | gt]}
      end)
    end)

    node_stats  = stats_ms(node_times)
    edge_stats  = stats_ms(edge_times)
    graph_stats = stats_ms(graph_times)

    total_ops = nodes_count * repeat_factor + edges_count * repeat_factor + 1
    total_time_ms = node_stats.avg + edge_stats.avg + graph_stats.avg
    ops_per_sec = if total_time_ms > 0, do: total_ops / (total_time_ms / 1000.0), else: 0.0
    time_per_op_us = if total_ops > 0, do: (total_time_ms * 1000.0) / total_ops, else: 0.0

    sched = :erlang.system_info(:schedulers_online)
    mem = :erlang.memory()

    Logger.info("\n🎯 HEAVY ADT PERFORMANCE RESULTS")
    Logger.info("=" |> String.duplicate(80))

    Logger.info("\n⚙️  ENVIRONMENT")
    Logger.info("-" |> String.duplicate(50))
    Logger.info("Schedulers: #{sched}")
    Logger.info("Elixir: #{System.version()}  OTP: #{System.otp_release()}")
    Logger.info("Memory (MB): total=#{Float.round(mem[:total] / 1_048_576, 1)}  processes=#{Float.round(mem[:processes] / 1_048_576, 1)}  binary=#{Float.round(mem[:binary] / 1_048_576, 1)}")

    Logger.info("\n📦 DATASET")
    Logger.info("-" |> String.duplicate(50))
    Logger.info("Nodes: #{nodes_count}  Edges: #{edges_count}  Repeat: #{repeat_factor}")

    Logger.info("\n⏱️  TIMINGS (ms) — per phase across runs")
    Logger.info("-" |> String.duplicate(50))
    Logger.info("Nodes   -> min=#{round(node_stats.min)}  p50=#{round(node_stats.p50)}  avg=#{Float.round(node_stats.avg,1)}  p95=#{round(node_stats.p95)}  max=#{round(node_stats.max)}")
    Logger.info("Edges   -> min=#{round(edge_stats.min)}  p50=#{round(edge_stats.p50)}  avg=#{Float.round(edge_stats.avg,1)}  p95=#{round(edge_stats.p95)}  max=#{round(edge_stats.max)}")
    Logger.info("Graph   -> min=#{round(graph_stats.min)} p50=#{round(graph_stats.p50)} avg=#{Float.round(graph_stats.avg,1)} p95=#{round(graph_stats.p95)} max=#{round(graph_stats.max)}")

    Logger.info("\n🚀 THROUGHPUT")
    Logger.info("-" |> String.duplicate(50))
    Logger.info("Total Operations (approx): #{total_ops}")
    Logger.info("Total Time (avg over phases): #{Float.round(total_time_ms, 1)}ms")
    Logger.info("Ops/sec: #{round(ops_per_sec)}")
    Logger.info("Time/op: #{Float.round(time_per_op_us, 1)}μs")

    IO.puts("\n🎯 HEAVY BENCH SUMMARY (stdout)")
    IO.puts("=" |> String.duplicate(50))
    IO.puts("Nodes=#{nodes_count} Edges=#{edges_count} Repeat=#{repeat_factor} Runs=#{runs} Parallel=#{par_enabled} MaxConc=#{max_conc}")
    IO.puts("Nodes(ms) min=#{round(node_stats.min)} p50=#{round(node_stats.p50)} avg=#{Float.round(node_stats.avg,1)} p95=#{round(node_stats.p95)} max=#{round(node_stats.max)}")
    IO.puts("Edges(ms) min=#{round(edge_stats.min)} p50=#{round(edge_stats.p50)} avg=#{Float.round(edge_stats.avg,1)} p95=#{round(edge_stats.p95)} max=#{round(edge_stats.max)}")
    IO.puts("Graph(ms) min=#{round(graph_stats.min)} p50=#{round(graph_stats.p50)} avg=#{Float.round(graph_stats.avg,1)} p95=#{round(graph_stats.p95)} max=#{round(graph_stats.max)}")
    IO.puts("Ops/sec=#{round(ops_per_sec)}  Time/op(μs)=#{Float.round(time_per_op_us, 1)}")

    :ok
  end
end

HeavyADTBench.run()
