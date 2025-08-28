#!/usr/bin/env elixir

# Concurrency Sweep for Heavy Enhanced ADT workloads (no WarpEngine deps)
# - Generates dataset once
# - Sweeps concurrency levels (CONC env or default 1,2,3,4,6,8,12,16,20,24)
# - Warmups + multiple measured trials per level
# - Computes best, median, p50, p90 ops/sec

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# ---------- Helpers ----------
now_ns = fn -> System.monotonic_time(:nanosecond) end
measure_ms = fn fun -> t0 = now_ns.(); res = fun.(); { (now_ns.() - t0) / 1_000_000, res } end

env_int = fn var, default ->
  case System.get_env(var) do
    nil -> default
    val ->
      case Integer.parse(val) do
        {i, _} -> i
        :error -> default
      end
  end
end

parse_conc = fn ->
  case System.get_env("CONC") do
    nil -> [1, 2, 3, 4, 6, 8, 12, 16, 20, 24]
    csv -> String.split(csv, ",") |> Enum.map(&String.to_integer/1)
  end
end

ceil_div = fn a, b -> div(a + b - 1, b) end

stats = fn samples ->
  s = Enum.sort(samples)
  n = length(s)
  mid = div(n, 2)
  p = fn perc -> Enum.at(s, min(n-1, round((perc/100) * max(n-1,0)))) end
  %{min: hd(s), p50: p.(50), median: Enum.at(s, mid), p90: p.(90), max: List.last(s)}
end

# ---------- Config ----------
nodes_count   = env_int.("BENCH_NODES", 10_000)
edges_count   = env_int.("BENCH_EDGES", 20_000)
repeat_factor = env_int.("BENCH_REPEAT", 5)
warmups       = env_int.("WARMUPS", 1)
trials        = env_int.("TRIALS", 5)
conc_levels   = parse_conc.()

IO.puts("⚙️  Concurrency Sweep Config: nodes=#{nodes_count} edges=#{edges_count} repeat=#{repeat_factor} warmups=#{warmups} trials=#{trials}")
IO.puts("   Levels: #{Enum.join(conc_levels, ",")}")

# ---------- Compile and generate dataset ----------
Logger.info("📚 Compiling simplified Enhanced ADT module...")
Code.compile_file("examples/simple_weighted_graph.ex")
Logger.info("✅ Simplified ADT ready")

Logger.info("📦 Generating dataset...")
{gen_nodes_ms, nodes} = measure_ms.(fn ->
  Enum.map(1..nodes_count, fn i ->
    SimpleWeightedGraph.new_node(
      "node_#{i}", "Node #{i}", %{bench: true, idx: i, attr: :erlang.phash2(i, 10)},
      :rand.uniform(), :rand.uniform(), DateTime.utc_now(), :bench
    )
  end)
end)

node_ids = Enum.map(nodes, & &1.id)
{gen_edges_ms, edges} = measure_ms.(fn ->
  Enum.map(1..edges_count, fn i ->
    from = Enum.at(node_ids, rem(i - 1, nodes_count))
    to   = Enum.at(node_ids, rem(i, nodes_count))
    SimpleWeightedGraph.new_edge(
      "edge_#{i}", from, to, :rand.uniform(), :rand.uniform(), :bench_rel,
      %{w: :rand.uniform()}, DateTime.utc_now(), :rand.uniform()
    )
  end)
end)

Logger.info("📦 Data ready: gen_nodes=#{Float.round(gen_nodes_ms, 1)}ms, gen_edges=#{Float.round(gen_edges_ms, 1)}ms")

# ---------- Workloads (sequential) ----------
node_reduce_seq = fn ->
  Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
    {sum, _hist} =
      Enum.reduce(nodes, {0.0, %{}}, fn n, {s, hist} ->
        if is_nil(n.id) or is_nil(n.label) or is_nil(n.properties), do: raise("Invalid node")
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
        if is_nil(e.id) or is_nil(e.from_node) or is_nil(e.to_node), do: raise("Invalid edge")
        if e.weight < 0.0 or e.weight > 1.0, do: raise("bad weight")
        if e.frequency < 0.0 or e.frequency > 1.0, do: raise("bad frequency")
        s + e.weight * e.frequency
      end)
    acc + total
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

# ---------- Parallelized variants ----------
node_reduce_par = fn max_conc ->
  chunk = max(1, ceil_div.(length(nodes), max_conc))
  Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
    partials =
      Task.async_stream(
        Stream.chunk_every(nodes, chunk),
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
      |> Enum.map(fn {:ok, {sum, _}} -> sum end)
    acc + Enum.sum(partials)
  end)
end

edge_reduce_par = fn max_conc ->
  chunk = max(1, ceil_div.(length(edges), max_conc))
  Enum.reduce(1..repeat_factor, 0.0, fn _, acc ->
    partials =
      Task.async_stream(
        Stream.chunk_every(edges, chunk),
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

build_graph_par = fn max_conc ->
  chunk = max(1, ceil_div.(length(edges), max_conc))
  parts =
    Task.async_stream(
      Stream.chunk_every(edges, chunk),
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
    |> Enum.map(fn {:ok, pair} -> pair end)
  {adj, _} = Enum.reduce(parts, {%{}, %{}}, fn {a, d}, {acc_a, acc_d} ->
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

# ---------- Sweep ----------
IO.puts("\n🎯 Concurrency Sweep (#{length(conc_levels)} levels)")

total_ops = nodes_count * repeat_factor + edges_count * repeat_factor + 1

Enum.each(conc_levels, fn conc ->
  IO.puts("\n== Concurrency level: #{conc} ==")

  # Warmups
  Enum.each(1..warmups, fn _ ->
    :erlang.garbage_collect()
    _ = measure_ms.(fn -> node_reduce_par.(conc) end)
    _ = measure_ms.(fn -> edge_reduce_par.(conc) end)
    _ = measure_ms.(fn -> build_graph_par.(conc) end)
  end)

  # Trials
  results = for _t <- 1..trials do
    :erlang.garbage_collect()
    {tn, _} = measure_ms.(fn -> node_reduce_par.(conc) end)
    {te, _} = measure_ms.(fn -> edge_reduce_par.(conc) end)
    {tg, _} = measure_ms.(fn -> build_graph_par.(conc) end)
    total_ms = tn + te + tg
    ops_sec = if total_ms > 0, do: total_ops / (total_ms / 1000.0), else: 0.0
    %{ms: total_ms, ops_sec: ops_sec}
  end

  rates = Enum.map(results, & &1.ops_sec)
  s = stats.(rates)
  best = Enum.max_by(results, & &1.ops_sec)
  IO.puts("   • best #{Float.round(best.ms,1)}ms (#{round(best.ops_sec)} ops/sec), median #{round(s.median)} (p50 #{round(s.p50)}, p90 #{round(s.p90)})")
end)
