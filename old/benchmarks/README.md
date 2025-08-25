### warp_engine

mix run benchmarks/dynamic_performance_comparison.exs &> benchmarks/dynamic_performance_comparison.txt
mix run benchmarks/final_redis_benchmark.exs &> benchmarks/final_redis_benchmark.txt
mix run benchmarks/fixed_rabbitmq_comparison.exs &> benchmarks/fixed_rabbitmq_comparison.txt
mix run benchmarks/optimized_redis_benchmark.exs &> benchmarks/optimized_redis_benchmark.txt
mix run benchmarks/phase6_6_wal_benchmark.exs &> benchmarks/phase6_6_wal_benchmark.txt
mix run benchmarks/rabbitmq_vs_warp_engine_comparison.exs &> benchmarks/rabbitmq_vs_warp_engine_comparison.txt
mix run benchmarks/redis_vs_warp_engine_simple.exs &> benchmarks/redis_vs_warp_engine_simple.txt
elixir benchmarks/benchmark.exs &> benchmarks/benchmark.txt


### examples

mix run benchmarks/weighted_graph_benchmark.exs &> benchmarks/weighted_graph_benchmark.txt
mix run benchmarks/optimized_weighted_benchmark.exs &> benchmarks/optimized_weighted_benchmark.txt
mix run benchmarks/heavy_weighted_graph_benchmark.exs &> benchmarks/heavy_weighted_graph_benchmark.txt


### big data
mix run benchmarks/big_data_scaling_test.exs &> benchmarks/big_data_scaling_test.txt
mix run benchmarks/extreme_scale_benchmark.exs &> benchmarks/extreme_scale_benchmark.txt


### parser
