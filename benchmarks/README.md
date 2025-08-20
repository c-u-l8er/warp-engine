### islab

mix run benchmarks/dynamic_performance_comparison.exs &> benchmarks/dynamic_performance_comparison.txt
mix run benchmarks/final_redis_benchmark.exs &> benchmarks/final_redis_benchmark.txt
mix run benchmarks/fixed_rabbitmq_comparison.exs &> benchmarks/fixed_rabbitmq_comparison.txt
mix run benchmarks/optimized_redis_benchmark.exs &> benchmarks/optimized_redis_benchmark.txt
mix run benchmarks/phase6_6_wal_benchmark.exs &> benchmarks/phase6_6_wal_benchmark.txt
mix run benchmarks/rabbitmq_vs_islab_comparison.exs &> benchmarks/rabbitmq_vs_islab_comparison.txt
mix run benchmarks/redis_vs_islab_simple.exs &> benchmarks/redis_vs_islab_simple.txt
elixir benchmarks/benchmark.exs &> benchmarks/benchmark.txt


### examples

mix run benchmarks/weighted_graph_benchmark.exs &> benchmarks/weighted_graph_benchmark.txt
mix run benchmarks/optimized_weighted_benchmark.exs &> benchmarks/optimized_weighted_benchmark.txt
mix run benchmarks/simple_weighted_graph_benchmark.exs &> benchmarks/simple_weighted_graph_benchmark.txt