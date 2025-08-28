#!/usr/bin/env elixir

# Minimal test for Enhanced ADT core functionality
IO.puts("🚀 Starting minimal Enhanced ADT test...")

# Step 1: Test basic compilation
IO.puts("📚 Step 1: Compiling simplified Enhanced ADT module...")
try do
  Code.compile_file("examples/simple_weighted_graph.ex")
  IO.puts("✅ Step 1: Compilation successful")
rescue
  error -> IO.puts("❌ Step 1: Compilation failed: #{inspect(error)}")
end

# Step 2: Test basic module loading
IO.puts("🔍 Step 2: Testing module loading...")
try do
  if Code.ensure_loaded(SimpleWeightedGraph) == {:module, SimpleWeightedGraph} do
    IO.puts("✅ Step 2: Module loaded successfully")
  else
    IO.puts("❌ Step 2: Module loading failed")
  end
rescue
  error -> IO.puts("❌ Step 2: Module loading error: #{inspect(error)}")
end

# Step 3: Test basic function calls
IO.puts("🔍 Step 3: Testing basic function calls...")
try do
  # Test node creation
  test_node = SimpleWeightedGraph.new_node(
    "test_node_1",
    "Test Node",
    %{test: true},
    0.8,
    0.7,
    DateTime.utc_now(),
    :test
  )
  IO.puts("✅ Step 3a: Node creation successful")

  # Test edge creation
  test_edge = SimpleWeightedGraph.new_edge(
    "test_edge_1",
    "test_node_1",
    "test_node_2",
    0.9,
    0.8,
    :test_relationship,
    %{test: true},
    DateTime.utc_now(),
    0.85
  )
  IO.puts("✅ Step 3b: Edge creation successful")

  # Test graph creation
  test_graph = SimpleWeightedGraph.new_connected_graph(
    [test_node],
    [test_edge],
    :test_topology
  )
  IO.puts("✅ Step 3c: Graph creation successful")

rescue
  error -> IO.puts("❌ Step 3: Function call error: #{inspect(error)}")
end

# Step 4: Test validation functions
IO.puts("🔍 Step 4: Testing validation functions...")
try do
  test_node = SimpleWeightedGraph.new_node(
    "test_node_2",
    "Test Node 2",
    %{test: true},
    0.6,
    0.5,
    DateTime.utc_now(),
    :test
  )

  case SimpleWeightedGraph.validate_node(test_node) do
    {:ok, _} -> IO.puts("✅ Step 4a: Node validation successful")
    {:error, reason} -> IO.puts("❌ Step 4a: Node validation failed: #{reason}")
  end

rescue
  error -> IO.puts("❌ Step 4: Validation error: #{inspect(error)}")
end

IO.puts("🎉 Minimal test completed!")
IO.puts("🔍 Final status: COMPLETED")
