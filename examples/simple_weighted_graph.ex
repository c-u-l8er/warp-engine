defmodule SimpleWeightedGraph do
  @moduledoc """
  Simple Weighted Property Graph using Enhanced ADT WITH Physics Annotations

  This module demonstrates how to define graph data structures with physics annotations
  that enable database performance optimizations including:

  - **Gravitational Mass**: Affects shard placement and routing for optimal data access
  - **Quantum Entanglement Potential**: Enables smart correlations and relationship discovery
  - **Temporal Weight**: Optimizes data lifecycle management and archival
  - **Quantum Entanglement Groups**: Enables wormhole routing for related data

  These physics annotations allow WarpEngine to automatically optimize:
  - Data placement across spacetime shards
  - Wormhole network creation for fast cross-references
  - Quantum correlation detection for smart pre-fetching
  - Temporal data lifecycle management
  """

  use EnhancedADT

  require Logger

  # =============================================================================
  # GRAPH ADT DEFINITIONS WITH PHYSICS ANNOTATIONS
  # =============================================================================

  @doc """
  Graph Node - Represents entities in the weighted property graph.

  Physics annotations enable database performance optimizations:
  - importance_score → gravitational_mass (affects shard placement and routing)
  - activity_level → quantum_entanglement_potential (enables smart correlations)
  - created_at → temporal_weight (optimizes data lifecycle management)
  - properties → quantum_entanglement_group (groups related data for wormhole routing)
  """
  defproduct GraphNode do
    field id :: String.t()
    field label :: String.t()
    field properties :: map(), physics: :quantum_entanglement_group
    field importance_score :: float(), physics: :gravitational_mass
    field activity_level :: float(), physics: :quantum_entanglement_potential
    field created_at :: DateTime.t(), physics: :temporal_weight
    field node_type :: atom()
  end

  # Graph Edge - Represents weighted relationships between nodes
  # Physics annotations enable database performance optimizations:
  # - weight → gravitational_mass (affects shard placement and routing)
  # - frequency → quantum_entanglement_potential (enables smart correlations)
  # - created_at → temporal_weight (optimizes data lifecycle management)
  # - properties → quantum_entanglement_group (groups related data for wormhole routing)
  # - relationship_strength → quantum_entanglement_potential (correlation strength)
  defproduct GraphEdge do
    field id :: String.t()
    field from_node :: String.t()
    field to_node :: String.t()
    field weight :: float(), physics: :gravitational_mass
    field frequency :: float(), physics: :quantum_entanglement_potential
    field relationship_type :: atom()
    field properties :: map(), physics: :quantum_entanglement_group
    field created_at :: DateTime.t(), physics: :temporal_weight
    field relationship_strength :: float(), physics: :quantum_entanglement_potential
  end

  # Weighted Graph Structure - Sum type representing different graph topologies
  defsum WeightedGraph do
    variant EmptyGraph
    variant SingleNode, node :: GraphNode.t()
    variant ConnectedGraph,
      nodes :: [GraphNode.t()],
      edges :: [GraphEdge.t()],
      topology_type :: atom()
    variant ClusteredGraph,
      clusters :: [GraphCluster.t()],
      inter_cluster_edges :: [GraphEdge.t()],
      clustering_algorithm :: atom()
    variant HierarchicalGraph,
      root :: GraphNode.t(),
      children :: [rec(WeightedGraph)],
      hierarchy_type :: atom()
  end

  # Graph Cluster - Represents clustered subgraphs
  # Physics annotations enable database performance optimizations:
  # - cohesion_score → quantum_entanglement_potential (enables smart correlations and wormhole routing)
  defproduct GraphCluster do
    field id :: String.t()
    field nodes :: [GraphNode.t()]
    field internal_edges :: [GraphEdge.t()]
    field cluster_type :: atom()
    field cohesion_score :: float(), physics: :quantum_entanglement_potential
  end

  # =============================================================================
  # BASIC OPERATIONS (NO WARPENGINE INTEGRATION)
  # =============================================================================

  @doc """
  Create a new graph node.
  """
  def new_node(id, label, properties, importance_score, activity_level, created_at, node_type) do
    %GraphNode{
      id: id,
      label: label,
      properties: properties,
      importance_score: importance_score,
      activity_level: activity_level,
      created_at: created_at,
      node_type: node_type
    }
  end

  @doc """
  Create a new graph edge.
  """
  def new_edge(id, from_node, to_node, weight, frequency, relationship_type, properties, created_at, relationship_strength) do
    %GraphEdge{
      id: id,
      from_node: from_node,
      to_node: to_node,
      weight: weight,
      frequency: frequency,
      relationship_type: relationship_type,
      properties: properties,
      created_at: created_at,
      relationship_strength: relationship_strength
    }
  end

  @doc """
  Create a connected graph.
  """
  def new_connected_graph(nodes, edges, topology_type) do
    %{__variant__: :ConnectedGraph, nodes: nodes, edges: edges, topology_type: topology_type}
  end

  @doc """
  Validate node structure.
  """
  def validate_node(%GraphNode{} = node) do
    cond do
      is_nil(node.id) -> {:error, "Missing node ID"}
      is_nil(node.label) -> {:error, "Missing node label"}
      is_nil(node.properties) -> {:error, "Missing node properties"}
      is_nil(node.importance_score) -> {:error, "Missing importance score"}
      is_nil(node.activity_level) -> {:error, "Missing activity level"}
      is_nil(node.created_at) -> {:error, "Missing creation date"}
      is_nil(node.node_type) -> {:error, "Missing node type"}
      node.importance_score < 0.0 or node.importance_score > 1.0 ->
        {:error, "Invalid importance score: #{node.importance_score}"}
      node.activity_level < 0.0 or node.activity_level > 1.0 ->
        {:error, "Invalid activity level: #{node.activity_level}"}
      true -> {:ok, node}
    end
  end

  @doc """
  Validate edge structure.
  """
  def validate_edge(%GraphEdge{} = edge) do
    cond do
      is_nil(edge.id) -> {:error, "Missing edge ID"}
      is_nil(edge.from_node) -> {:error, "Missing from node"}
      is_nil(edge.to_node) -> {:error, "Missing to node"}
      is_nil(edge.weight) -> {:error, "Missing weight"}
      is_nil(edge.frequency) -> {:error, "Missing frequency"}
      is_nil(edge.relationship_type) -> {:error, "Missing relationship type"}
      is_nil(edge.properties) -> {:error, "Missing properties"}
      is_nil(edge.created_at) -> {:error, "Missing creation date"}
      is_nil(edge.relationship_strength) -> {:error, "Missing relationship strength"}
      edge.weight < 0.0 or edge.weight > 1.0 ->
        {:error, "Invalid weight: #{edge.weight}"}
      edge.frequency < 0.0 or edge.frequency > 1.0 ->
        {:error, "Invalid frequency: #{edge.frequency}"}
      edge.relationship_strength < 0.0 or edge.relationship_strength > 1.0 ->
        {:error, "Invalid relationship strength: #{edge.relationship_strength}"}
      true -> {:ok, edge}
    end
  end

  @doc """
  Validate graph structure.
  """
  def validate_graph(%{__variant__: :ConnectedGraph, nodes: nodes, edges: edges, topology_type: topology_type}) do
    cond do
      is_nil(nodes) -> {:error, "Missing nodes"}
      is_nil(edges) -> {:error, "Missing edges"}
      is_nil(topology_type) -> {:error, "Missing topology type"}
      not is_list(nodes) -> {:error, "Nodes must be a list"}
      not is_list(edges) -> {:error, "Edges must be a list"}
      true -> {:ok, %{__variant__: :ConnectedGraph, nodes: nodes, edges: edges, topology_type: topology_type}}
    end
  end

  def validate_graph(_), do: {:error, "Invalid graph structure"}
end
