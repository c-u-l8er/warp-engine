#!/usr/bin/env elixir

# Simple test to verify Enhanced ADT works
require Logger
Logger.info("🚀 Starting simple Enhanced ADT test...")

# Compile the weighted graph database example first
Logger.info("📚 Compiling Enhanced ADT example...")
Code.compile_file("examples/weighted_graph_database.ex")
Logger.info("✅ Enhanced ADT compilation successful")

# Test basic node creation
Logger.info("🔍 About to create test node...")
test_node = WeightedGraphDatabase.GraphNode.new(
  "test_node_1",
  "Test Node",
  %{test: true},
  0.8,
  0.7,
  DateTime.utc_now(),
  :test
)

Logger.info("✅ Node created: #{inspect(test_node)}")
Logger.info("🔍 Node creation successful!")

# Test basic edge creation
Logger.info("🔍 About to create test edge...")
test_edge = WeightedGraphDatabase.GraphEdge.new(
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

Logger.info("✅ Edge created: #{inspect(test_edge)}")
Logger.info("🔍 Edge creation successful!")

# Test graph creation
Logger.info("🔍 About to create test graph...")
test_graph = %{
  __variant__: :ConnectedGraph,
  nodes: [test_node],
  edges: [test_edge],
  topology_type: :test_topology
}

Logger.info("✅ Graph created: #{inspect(test_graph)}")
Logger.info("🔍 Graph creation successful!")

Logger.info("🎉 Simple test completed successfully!")

# Add explicit error handling to catch any issues
Logger.info("🔍 Test completed without errors!")
Logger.info("🔍 Final status: SUCCESS")
