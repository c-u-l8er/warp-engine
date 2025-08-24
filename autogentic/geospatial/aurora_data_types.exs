
defmodule Aurora.DataTypes do
  @moduledoc """
  Enhanced ADT data types for Aurora Geospatial Intelligence Platform.

  This module defines the core mathematical data structures used by Aurora's
  spatial intelligence system, with automatic WarpEngine physics integration.

  All data types automatically leverage:
  - Gravitational routing for optimal data placement
  - Quantum entanglement for smart correlations
  - Spacetime sharding for performance optimization
  - Temporal weight for lifecycle management
  """

  use EnhancedADT

  # =============================================================================
  # CORE SPATIAL ENTITIES - Foundation data types for geospatial intelligence
  # =============================================================================

  @doc """
  Core geospatial entity with physics-enhanced optimization.

  Automatically configures WarpEngine storage based on entity characteristics:
  - High importance -> gravitational mass -> hot shard placement
  - High velocity -> quantum entanglement -> smart pre-fetching
  - Regional clustering -> spacetime sharding -> co-located storage
  """
  defproduct SpatialEntity do
    field id :: String.t()
    field coordinates :: {float(), float()}, physics: :spatial_clustering
    field altitude :: float(), physics: :gravitational_mass
    field velocity :: {float(), float()}, physics: :quantum_entanglement_potential
    field importance :: float(), physics: :gravitational_mass
    field entity_type :: atom()
    field region :: String.t(), physics: :spacetime_shard_hint
    field last_update :: DateTime.t(), physics: :temporal_weight
    field metadata :: map(), physics: :quantum_entanglement_group
  end

  @doc """
  Spatial relationship between entities with physics correlation.

  Automatically creates quantum entanglement between related entities
  for optimized relationship queries and predictive analysis.
  """
  defproduct SpatialRelationship do
    field id :: String.t()
    field from_entity :: String.t()
    field to_entity :: String.t()
    field relationship_type :: atom()
    field distance :: float(), physics: :gravitational_mass
    field interaction_strength :: float(), physics: :quantum_entanglement_potential
    field temporal_correlation :: float(), physics: :temporal_weight
    field context :: map(), physics: :quantum_entanglement_group
  end

  @doc """
  Location event for real-time spatial tracking.

  High-velocity events automatically get hot shard placement,
  while low-activity events get cold storage with temporal optimization.
  """
  defproduct LocationEvent do
    field id :: String.t()
    field entity_id :: String.t()
    field coordinates :: {float(), float()}, physics: :spatial_clustering
    field event_type :: atom()
    field velocity :: float(), physics: :gravitational_mass
    field accuracy :: float(), physics: :quantum_entanglement_potential
    field timestamp :: DateTime.t(), physics: :temporal_weight
    field source_system :: String.t()
  end

  # =============================================================================
  # SPATIAL NETWORKS - Complex relationship modeling with wormhole optimization
  # =============================================================================

    @doc """
  Spatial network topology with automatic wormhole generation.

  Recursive network structure enabling infinite spatial relationship nesting.
  Wormhole connections automatically optimize traversal across network layers.
  """
  defsum SpatialNetwork do
    variant IsolatedEntity, entity
    variant ConnectedEntities, primary, connections :: [rec(SpatialNetwork)], network_strength
    variant SpatialCluster, entities, sub_clusters :: [rec(SpatialNetwork)], cluster_cohesion
    variant TemporalSequence, entities, nested_sequences :: [rec(SpatialNetwork)], prediction_confidence
    variant QuantumSuperposition, entangled_networks :: [rec(SpatialNetwork)], coherence_level
    variant HierarchicalRegion, region_entity, child_regions :: [rec(SpatialNetwork)], spatial_depth
  end

  @doc """
  Entity state with predictive intelligence capabilities.

  State variants enable AI-powered transition prediction and
  autonomous state management with physics optimization.
  """
  defsum EntityState do
    variant Stationary, entity, position, duration_stability
    variant Moving, entity, trajectory, velocity, acceleration_trend
    variant Clustered, entity, cluster_members, spatial_cohesion
    variant Distributed, entity, geographic_spread, coordination_level
    variant Transitioning, entity, from_state, to_state, transition_probability
  end

  # =============================================================================
  # MORPHIC GEOFENCING - Adaptive boundaries with AI learning
  # =============================================================================

  @doc """
  Adaptive geofence with AI-powered morphic capabilities.

  Physics annotations enable automatic optimization based on
  geofence performance and learning patterns.
  """
  defproduct MorphicGeofence do
    field id :: String.t()
    field base_geometry :: map()
    field adaptation_rules :: [map()], physics: :quantum_entanglement_group
    field learning_rate :: float(), physics: :quantum_entanglement_potential
    field performance_score :: float(), physics: :gravitational_mass
    field context_weights :: map(), physics: :quantum_entanglement_group
    field adaptation_history :: [map()], physics: :temporal_weight
    field created_at :: DateTime.t(), physics: :temporal_weight
  end

    @doc """
  Geofence state with AI-driven adaptation and hierarchical nesting.

  Recursive boundary structure enabling nested geofences with
  automatic parent-child relationship optimization.
  """
  defsum GeofenceState do
    variant StaticBoundary, geometry, trigger_rules
    variant AdaptiveBoundary, base_geometry, learned_adjustments, adaptation_confidence
    variant PredictiveBoundary, current_geometry, predicted_shapes, prediction_accuracy
    variant ContextAwareBoundary, geometries_by_context, active_context, switching_intelligence
    variant LearningBoundary, geometry, learning_data, optimization_targets
    variant NestedBoundary, parent_geometry, child_boundaries :: [rec(GeofenceState)], hierarchy_depth
    variant CompoundBoundary, boundary_components :: [rec(GeofenceState)], combination_logic
  end

  @doc """
  Spatial indexing tree for high-performance spatial queries.

  Recursive tree structure automatically optimized by WarpEngine's
  gravitational routing and wormhole network generation.
  """
  defsum SpatialTree do
    variant SpatialLeaf, entities, bounding_box, leaf_capacity
    variant SpatialBranch, bounding_box, children :: [rec(SpatialTree)], split_dimension
    variant QuadTreeNode, bounds, quadrants :: [rec(SpatialTree)], node_depth
    variant RTreeNode, minimum_bounds, child_nodes :: [rec(SpatialTree)], node_level
    variant AdaptiveNode, current_bounds, adaptive_children :: [rec(SpatialTree)], optimization_score
  end

  @doc """
  Trajectory path with recursive branching and merging capabilities.

  Enables complex path planning with alternative routes and
  predictive path evolution based on real-time conditions.
  """
  defsum TrajectoryPath do
    variant LinearPath, start_point, end_point, waypoints
    variant BranchingPath, current_point, alternative_paths :: [rec(TrajectoryPath)], branch_probability
    variant MergingPath, converging_paths :: [rec(TrajectoryPath)], merge_point, merge_conditions
    variant AdaptivePath, base_path, path_variations :: [rec(TrajectoryPath)], adaptation_triggers
    variant PredictivePath, current_trajectory, predicted_branches :: [rec(TrajectoryPath)], confidence_scores
  end

  @doc """
  Entity relationship graph with recursive connection modeling.

  Represents complex entity relationships with automatic
  quantum entanglement optimization for related entities.
  """
  defsum EntityGraph do
    variant IsolatedEntity, entity_data, isolation_score
    variant DirectConnection, source_entity, target_entity, relationship_strength
    variant EntityCluster, cluster_entities, internal_connections :: [rec(EntityGraph)], cluster_cohesion
    variant HierarchicalRelation, parent_entity, child_relations :: [rec(EntityGraph)], hierarchy_level
    variant NetworkFragment, fragment_entities, fragment_connections :: [rec(EntityGraph)], fragment_importance
    variant QuantumEntangledGroup, entangled_entities, entanglement_graph :: [rec(EntityGraph)], coherence_level
  end

  # =============================================================================
  # PREDICTION & ANALYTICS - AI-powered spatial intelligence data types
  # =============================================================================

  @doc """
  Trajectory prediction with multi-horizon forecasting.

  Physics annotations optimize storage based on prediction accuracy
  and temporal relevance for maximum intelligence performance.
  """
  defproduct TrajectoryPrediction do
    field id :: String.t()
    field entity_id :: String.t()
    field prediction_horizons :: [atom()]
    field trajectory_data :: map(), physics: :quantum_entanglement_group
    field confidence_score :: float(), physics: :gravitational_mass
    field prediction_accuracy :: float(), physics: :quantum_entanglement_potential
    field model_version :: String.t()
    field created_at :: DateTime.t(), physics: :temporal_weight
  end

  @doc """
  Spatial pattern with anomaly detection intelligence.

  Automatically clusters related patterns and creates quantum
  entanglement for rapid anomaly correlation analysis.
  """
  defproduct SpatialPattern do
    field id :: String.t()
    field pattern_type :: atom()
    field spatial_signature :: map(), physics: :quantum_entanglement_group
    field anomaly_score :: float(), physics: :gravitational_mass
    field confidence_level :: float(), physics: :quantum_entanglement_potential
    field detection_frequency :: float(), physics: :temporal_weight
    field correlation_keys :: [String.t()], physics: :quantum_entanglement_group
  end

    @doc """
  Analytics result with recursive intelligence insights.

  Results can reference sub-analyses and related insights,
  creating deep analytical relationship networks.
  """
  defsum AnalyticsResult do
    variant SpatialInsight, insight_type, confidence, recommendations
    variant AnomalyDetection, anomaly_type, severity, affected_entities
    variant PredictiveWarning, warning_type, probability, suggested_actions
    variant PerformanceMetrics, metric_type, values, optimization_suggestions
    variant PatternRecognition, pattern_type, matches, correlation_strength
    variant CompositeAnalysis, primary_result, supporting_analyses :: [rec(AnalyticsResult)], synthesis_confidence
    variant HierarchicalInsight, top_level_insight, detailed_breakdowns :: [rec(AnalyticsResult)], insight_depth
    variant CorrelatedResults, result_cluster :: [rec(AnalyticsResult)], correlation_matrix, cluster_significance
  end

  # =============================================================================
  # SYSTEM INTEGRATION - External system and workflow data types
  # =============================================================================

  @doc """
  Agent workflow task with spatial intelligence.

  Physics annotations optimize task routing and coordination
  based on urgency, location, and collaboration requirements.
  """
  defproduct SpatialTask do
    field id :: String.t()
    field location :: {float(), float()}, physics: :spatial_clustering
    field urgency :: float(), physics: :gravitational_mass
    field collaboration_required :: boolean(), physics: :quantum_entanglement_potential
    field deadline :: DateTime.t(), physics: :temporal_weight
    field required_capabilities :: [String.t()], physics: :quantum_entanglement_group
    field assigned_agent :: String.t()
    field task_context :: map()
  end

  @doc """
  Workflow state for spatial task coordination.

  Enables AI-powered task assignment and autonomous
  workflow optimization with spatial intelligence.
  """
  defsum WorkflowState do
    variant TaskPending, task, priority_score
    variant TaskAssigned, task, agent, assignment_confidence
    variant TaskActive, task, agent, progress_metrics
    variant TaskCoordinating, primary_task, related_tasks, coordination_strength
    variant TaskCompleted, task, results, performance_analysis
  end

  @doc """
  System event for Aurora integration.

  Events are automatically routed based on importance and
  correlated with related system events for intelligence analysis.
  """
  defsum SystemEvent do
    variant LocationUpdate, entity_id, coordinates, timestamp, source_system
    variant EntityStateChange, entity_id, old_state, new_state, change_reason
    variant GeofenceTriggered, geofence_id, entity_id, trigger_type, context
    variant AnomalyDetected, anomaly_type, affected_entities, severity, detection_context
    variant PredictionValidated, prediction_id, actual_outcome, accuracy_score
    variant SystemAlert, alert_type, severity, affected_components, mitigation_actions
  end

  # =============================================================================
  # HELPER FUNCTIONS - Physics parameter extraction and optimization
  # =============================================================================

  @doc """
  Extract physics parameters from any Aurora data type for WarpEngine optimization.

  Automatically analyzes data type physics annotations and generates
  optimal WarpEngine cosmic_put options for maximum performance.
  """
  def extract_physics_parameters(%{__struct__: module} = data) do
    if function_exported?(module, :__adt_physics_config__, 0) do
      module.extract_physics_context(data)
    else
      # Default physics parameters for non-ADT data
      %{
        access_pattern: :warm,
        priority: :normal,
        entangled_with: [],
        temporal_weight: 1.0
      }
    end
  end

  @doc """
  Convert physics parameters to WarpEngine cosmic_put options.

  Translates Aurora physics context into WarpEngine-compatible
  storage optimization parameters.
  """
  def to_warp_engine_options(physics_params) do
    base_options = [
      access_pattern: Map.get(physics_params, :spatial_clustering, :warm),
      priority: determine_priority_from_mass(Map.get(physics_params, :gravitational_mass, 1.0))
    ]

    # Add entanglement if specified
    case Map.get(physics_params, :quantum_entanglement_group) do
      nil -> base_options
      [] -> base_options
      entangled_keys when is_list(entangled_keys) ->
        [{:entangled_with, entangled_keys} | base_options]
      single_key ->
        [{:entangled_with, [single_key]} | base_options]
    end
  end

  # Helper for priority determination
  defp determine_priority_from_mass(mass) when mass > 0.8, do: :critical
  defp determine_priority_from_mass(mass) when mass > 0.5, do: :high
  defp determine_priority_from_mass(mass) when mass > 0.2, do: :normal
  defp determine_priority_from_mass(_), do: :low
end
