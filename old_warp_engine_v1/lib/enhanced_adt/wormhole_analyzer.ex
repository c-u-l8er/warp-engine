defmodule EnhancedADT.WormholeAnalyzer do
  @moduledoc """
  Wormhole route analysis and automatic creation for Enhanced ADT.

  This module analyzes ADT structures and data access patterns to automatically
  create optimal wormhole networks in WarpEngine. It provides intelligent routing
  decisions based on mathematical structure analysis.

  ## Analysis Features

  - **Pattern Recognition**: Detects data access patterns that benefit from wormholes
  - **Route Optimization**: Calculates optimal wormhole routes for cross-references
  - **Dynamic Adaptation**: Adapts wormhole networks based on actual usage patterns
  - **Performance Prediction**: Predicts performance benefits of wormhole creation
  - **Network Topology**: Generates optimal network topologies for ADT structures
  """

  require Logger

  @doc """
  Analyze potential wormhole routes for cross-reference patterns.

  Given a list of cross-reference candidates, analyzes the benefit of creating
  wormhole routes and returns recommendations for route creation.
  """
  def analyze_potential_routes(cross_reference_candidates) do
    Logger.debug("🌀 Analyzing #{length(cross_reference_candidates)} wormhole route candidates")

    # Analyze each candidate for wormhole potential
    route_analyses = Enum.map(cross_reference_candidates, &analyze_single_route/1)

    # Filter for beneficial routes
    beneficial_routes = Enum.filter(route_analyses, fn analysis ->
      analysis.benefit_score >= 0.4 and analysis.creation_feasibility == :feasible
    end)

    # Create recommendations
    recommendations = generate_route_recommendations(beneficial_routes)

    # Log analysis results
    Logger.debug("🌀 Wormhole analysis complete: #{length(beneficial_routes)}/#{length(cross_reference_candidates)} routes recommended")

    %{
      analyzed_candidates: route_analyses,
      beneficial_routes: beneficial_routes,
      recommendations: recommendations,
      summary: %{
        total_analyzed: length(cross_reference_candidates),
        recommended_count: length(beneficial_routes),
        estimated_performance_gain: calculate_total_performance_gain(beneficial_routes)
      }
    }
  end

  @doc """
  Create automatic wormhole routes based on ADT structure analysis.

  Analyzes the structure of ADT types and automatically creates wormhole
  routes that optimize traversal between related data items.
  """
  def create_automatic_routes_for_adt(adt_module, instances) when is_list(instances) do
    # Analyze ADT structure for wormhole opportunities
    structure_analysis = analyze_adt_structure(adt_module)

    # Analyze actual instance relationships
    instance_analysis = analyze_instance_relationships(instances)

    # Generate optimal wormhole network
    network_topology = generate_network_topology(structure_analysis, instance_analysis)

    # Create wormhole routes in WarpEngine
    creation_results = create_wormhole_routes(network_topology.routes)

    %{
      structure_analysis: structure_analysis,
      instance_analysis: instance_analysis,
      network_topology: network_topology,
      creation_results: creation_results,
      performance_metrics: calculate_network_performance_metrics(creation_results)
    }
  end

  @doc """
  Optimize existing wormhole network based on usage patterns.

  Analyzes actual wormhole usage patterns and optimizes the network by
  strengthening frequently used routes and removing underutilized ones.
  """
  def optimize_existing_network(usage_metrics) do
    Logger.info("🌀 Optimizing wormhole network based on usage patterns")

    # Analyze usage patterns
    usage_analysis = analyze_usage_patterns(usage_metrics)

    # Generate optimization recommendations
    optimizations = generate_optimization_recommendations(usage_analysis)

    # Apply optimizations
    optimization_results = apply_network_optimizations(optimizations)

    Logger.info("🌀 Network optimization complete: #{optimization_results.routes_strengthened} strengthened, #{optimization_results.routes_removed} removed")

    %{
      usage_analysis: usage_analysis,
      optimizations: optimizations,
      results: optimization_results,
      performance_improvement: optimization_results.performance_gain
    }
  end

  # Single Route Analysis

  defp analyze_single_route(route_candidate) do
    # Analyze individual route for wormhole potential
    distance_benefit = calculate_distance_benefit(route_candidate)
    frequency_score = estimate_frequency_score(route_candidate)
    creation_cost = estimate_creation_cost(route_candidate)
    maintenance_cost = estimate_maintenance_cost(route_candidate)

    benefit_score = (distance_benefit + frequency_score) - (creation_cost + maintenance_cost)

    %{
      candidate: route_candidate,
      distance_benefit: distance_benefit,
      frequency_score: frequency_score,
      creation_cost: creation_cost,
      maintenance_cost: maintenance_cost,
      benefit_score: max(0.0, benefit_score),
      creation_feasibility: determine_creation_feasibility(route_candidate, benefit_score),
      priority: determine_route_priority(benefit_score, frequency_score)
    }
  end

  defp calculate_distance_benefit(route_candidate) do
    # Calculate benefit based on distance reduction
    # Higher benefit for routes that significantly reduce traversal distance
    case estimate_route_distance(route_candidate) do
      distance when distance > 3 -> 0.8
      distance when distance > 2 -> 0.6
      distance when distance > 1 -> 0.4
      _ -> 0.2
    end
  end

  defp estimate_frequency_score(route_candidate) do
    # Estimate how frequently this route would be used
    # Based on data type patterns and common access patterns
    case analyze_route_pattern(route_candidate) do
      :high_frequency -> 0.9
      :medium_frequency -> 0.6
      :low_frequency -> 0.3
      :unknown -> 0.4
    end
  end

  defp estimate_creation_cost(_route_candidate) do
    # Estimate cost of creating this wormhole route
    # Lower cost for simple routes, higher for complex ones
    0.1  # Base creation cost
  end

  defp estimate_maintenance_cost(route_candidate) do
    # Estimate ongoing maintenance cost
    case estimate_route_complexity(route_candidate) do
      :simple -> 0.05
      :moderate -> 0.1
      :complex -> 0.2
    end
  end

  defp determine_creation_feasibility(_route_candidate, benefit_score) do
    cond do
      benefit_score >= 0.6 -> :highly_feasible
      benefit_score >= 0.4 -> :feasible
      benefit_score >= 0.2 -> :marginal
      true -> :not_feasible
    end
  end

  defp determine_route_priority(benefit_score, frequency_score) do
    combined_score = benefit_score * 0.7 + frequency_score * 0.3

    cond do
      combined_score >= 0.8 -> :critical
      combined_score >= 0.6 -> :high
      combined_score >= 0.4 -> :medium
      true -> :low
    end
  end

  # ADT Structure Analysis

  defp analyze_adt_structure(adt_module) do
    # Analyze ADT module structure for wormhole opportunities
    structure_info = %{
      module: adt_module,
      adt_type: get_adt_type(adt_module),
      fields: get_adt_fields(adt_module),
      cross_references: find_structural_cross_references(adt_module),
      complexity: calculate_structural_complexity(adt_module)
    }

    %{
      structure_info: structure_info,
      wormhole_opportunities: identify_structural_wormhole_opportunities(structure_info),
      recommended_topology: recommend_topology_for_structure(structure_info)
    }
  end

  defp get_adt_type(module) do
    cond do
      function_exported?(module, :__adt_type__, 0) -> module.__adt_type__()
      true -> :unknown
    end
  end

  defp get_adt_fields(module) do
    cond do
      function_exported?(module, :__adt_field_specs__, 0) -> module.__adt_field_specs__()
      function_exported?(module, :__adt_variants__, 0) -> module.__adt_variants__()
      true -> []
    end
  end

  defp find_structural_cross_references(module) do
    fields = get_adt_fields(module)

    case fields do
      field_specs when is_list(field_specs) ->
        Enum.filter(field_specs, fn field ->
          case field do
            %{type: type} -> is_reference_type?(type)
            _ -> false
          end
        end)

      _ -> []
    end
  end

  defp is_reference_type?(type) do
    # Determine if a type represents a reference to other data
    case type do
      {:recursive, _} -> true
      {{:., _, [{:__aliases__, _, _}, _]}, _, _} -> true  # Module.Type.t()
      {type_name, _, _} when is_atom(type_name) -> String.ends_with?(Atom.to_string(type_name), "_id")
      _ -> false
    end
  end

  defp calculate_structural_complexity(module) do
    fields = get_adt_fields(module)
    cross_refs = find_structural_cross_references(module)

    %{
      field_count: length(fields),
      cross_reference_count: length(cross_refs),
      complexity_score: length(fields) + (length(cross_refs) * 2)
    }
  end

  defp identify_structural_wormhole_opportunities(structure_info) do
    # Identify opportunities based on structure analysis
    opportunities = []

    # High cross-reference count suggests wormhole benefit
    opportunities = if structure_info.cross_references |> length() >= 2 do
      [%{type: :cross_reference_hub, priority: :high, reason: "Multiple cross-references"} | opportunities]
    else
      opportunities
    end

    # Complex structures benefit from shortcuts
    opportunities = if structure_info.complexity.complexity_score >= 8 do
      [%{type: :complexity_reduction, priority: :medium, reason: "High structural complexity"} | opportunities]
    else
      opportunities
    end

    opportunities
  end

  defp recommend_topology_for_structure(structure_info) do
    case {get_adt_type(structure_info.module), length(structure_info.cross_references)} do
      {:product, ref_count} when ref_count >= 3 -> :hub_and_spoke
      {:product, ref_count} when ref_count >= 1 -> :point_to_point
      {:sum, _} -> :variant_network
      _ -> :minimal
    end
  end

  # Instance Analysis

  defp analyze_instance_relationships(instances) do
    # Analyze actual relationships between ADT instances
    relationship_matrix = build_relationship_matrix(instances)

    %{
      instance_count: length(instances),
      relationship_matrix: relationship_matrix,
      connection_density: calculate_connection_density(relationship_matrix),
      hub_nodes: identify_hub_nodes(relationship_matrix),
      isolated_nodes: identify_isolated_nodes(relationship_matrix)
    }
  end

  defp build_relationship_matrix(instances) do
    # Build matrix of relationships between instances
    instance_keys = Enum.map(instances, &extract_instance_key/1)

    relationships = for {instance, i} <- Enum.with_index(instances),
                       {other_key, j} <- Enum.with_index(instance_keys),
                       i != j do
      strength = calculate_relationship_strength(instance, other_key)
      if strength > 0.2, do: {i, j, strength}, else: nil
    end
    |> Enum.reject(&is_nil/1)

    %{
      node_count: length(instance_keys),
      edges: relationships,
      density: length(relationships) / (length(instance_keys) * (length(instance_keys) - 1) / 2)
    }
  end

  defp extract_instance_key(%{id: id}) when is_binary(id), do: id
  defp extract_instance_key(%{__struct__: module} = instance) do
    # Generate key based on module and first few fields
    module_name = module |> Module.split() |> List.last() |> String.downcase()
    hash = :erlang.phash2(instance, 1000000)
    "#{module_name}:#{hash}"
  end
  defp extract_instance_key(instance), do: "unknown:#{:erlang.phash2(instance, 1000000)}"

  defp calculate_relationship_strength(instance, other_key) do
    # Calculate relationship strength between instance and another key
    instance_refs = extract_references_from_instance(instance)

    if Enum.member?(instance_refs, other_key) do
      0.8  # Direct reference
    else
      # Check for indirect relationships
      calculate_indirect_relationship_strength(instance, other_key)
    end
  end

  defp extract_references_from_instance(instance) do
    # Extract all reference-like values from instance
    instance
    |> Map.from_struct()
    |> Map.values()
    |> Enum.flat_map(&extract_references_from_value/1)
  end

  defp extract_references_from_value(value) when is_binary(value) do
    if String.contains?(value, ":") and String.length(value) > 5 do
      [value]
    else
      []
    end
  end
  defp extract_references_from_value(value) when is_list(value) do
    Enum.flat_map(value, &extract_references_from_value/1)
  end
  defp extract_references_from_value(%{id: id}) when is_binary(id), do: [id]
  defp extract_references_from_value(_), do: []

  defp calculate_indirect_relationship_strength(_instance, _other_key) do
    # Calculate indirect relationship strength (simplified)
    0.0
  end

  defp calculate_connection_density(%{node_count: node_count, edges: edges}) do
    if node_count > 1 do
      max_edges = node_count * (node_count - 1) / 2
      length(edges) / max_edges
    else
      0.0
    end
  end

  defp identify_hub_nodes(%{edges: edges}) do
    # Identify nodes with many connections (potential wormhole hubs)
    node_connections = Enum.reduce(edges, %{}, fn {source, target, _strength}, acc ->
      acc
      |> Map.update(source, 1, &(&1 + 1))
      |> Map.update(target, 1, &(&1 + 1))
    end)

    hub_threshold = 3  # Nodes with 3+ connections are hubs

    Enum.filter(node_connections, fn {_node, count} -> count >= hub_threshold end)
    |> Enum.map(fn {node, count} -> %{node: node, connection_count: count} end)
    |> Enum.sort_by(& &1.connection_count, :desc)
  end

  defp identify_isolated_nodes(%{node_count: node_count, edges: edges}) do
    connected_nodes = Enum.flat_map(edges, fn {source, target, _} -> [source, target] end)
                     |> Enum.uniq()

    all_nodes = 0..(node_count - 1) |> Enum.to_list()
    isolated = all_nodes -- connected_nodes

    Enum.map(isolated, fn node -> %{node: node, isolation_reason: :no_connections} end)
  end

  # Network Topology Generation

  defp generate_network_topology(structure_analysis, instance_analysis) do
    # Generate optimal network topology based on analyses
    base_topology = structure_analysis.recommended_topology

    # Adjust based on instance analysis
    adjusted_topology = adjust_topology_for_instances(base_topology, instance_analysis)

    # Generate specific routes
    routes = generate_routes_for_topology(adjusted_topology, structure_analysis, instance_analysis)

    %{
      base_topology: base_topology,
      adjusted_topology: adjusted_topology,
      routes: routes,
      estimated_performance: estimate_topology_performance(routes),
      maintenance_requirements: estimate_maintenance_requirements(routes)
    }
  end

  defp adjust_topology_for_instances(base_topology, instance_analysis) do
    case {base_topology, instance_analysis.connection_density} do
      {:minimal, density} when density > 0.3 -> :point_to_point
      {:point_to_point, density} when density > 0.6 -> :hub_and_spoke
      {:hub_and_spoke, density} when density > 0.8 -> :full_mesh
      _ -> base_topology
    end
  end

  defp generate_routes_for_topology(topology, structure_analysis, instance_analysis) do
    case topology do
      :hub_and_spoke -> generate_hub_and_spoke_routes(structure_analysis, instance_analysis)
      :point_to_point -> generate_point_to_point_routes(structure_analysis, instance_analysis)
      :full_mesh -> generate_full_mesh_routes(structure_analysis, instance_analysis)
      :variant_network -> generate_variant_network_routes(structure_analysis, instance_analysis)
      _ -> []
    end
  end

  defp generate_hub_and_spoke_routes(_structure_analysis, instance_analysis) do
    # Generate hub and spoke topology routes
    hub_nodes = instance_analysis.hub_nodes

    if length(hub_nodes) > 0 do
      primary_hub = List.first(hub_nodes)

      # Create routes from hub to all other nodes
      Enum.map(0..(instance_analysis.instance_count - 1), fn node_id ->
        if node_id != primary_hub.node do
          %{
            source: primary_hub.node,
            target: node_id,
            strength: calculate_hub_route_strength(primary_hub, node_id),
            route_type: :hub_spoke
          }
        end
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp generate_point_to_point_routes(_structure_analysis, instance_analysis) do
    # Generate point-to-point routes based on strongest connections
    instance_analysis.relationship_matrix.edges
    |> Enum.filter(fn {_source, _target, strength} -> strength >= 0.5 end)
    |> Enum.map(fn {source, target, strength} ->
      %{
        source: source,
        target: target,
        strength: strength,
        route_type: :point_to_point
      }
    end)
  end

  defp generate_full_mesh_routes(_structure_analysis, instance_analysis) do
    # Generate full mesh routes (all-to-all connections)
    node_count = instance_analysis.instance_count

    for i <- 0..(node_count - 1),
        j <- (i + 1)..(node_count - 1) do
      %{
        source: i,
        target: j,
        strength: 0.6,  # Default mesh strength
        route_type: :full_mesh
      }
    end
  end

  defp generate_variant_network_routes(structure_analysis, _instance_analysis) do
    # Generate routes for sum type variants
    case structure_analysis.structure_info.adt_type do
      :sum ->
        variants = structure_analysis.structure_info.fields

        # Create routes between related variants
        for {variant1, i} <- Enum.with_index(variants),
            {variant2, j} <- Enum.with_index(variants),
            i < j,
            variants_are_related?(variant1, variant2) do
          %{
            source: variant1.name,
            target: variant2.name,
            strength: calculate_variant_relationship_strength(variant1, variant2),
            route_type: :variant_connection
          }
        end

      _ -> []
    end
  end

  defp variants_are_related?(%{fields: fields1}, %{fields: fields2}) do
    # Check if variants have overlapping field types
    types1 = Enum.map(fields1, & &1.type) |> MapSet.new()
    types2 = Enum.map(fields2, & &1.type) |> MapSet.new()

    not MapSet.disjoint?(types1, types2)
  end

  defp calculate_variant_relationship_strength(variant1, variant2) do
    # Calculate relationship strength between variants
    common_types = count_common_field_types(variant1.fields, variant2.fields)
    base_strength = 0.4
    type_bonus = min(0.4, common_types * 0.2)

    base_strength + type_bonus
  end

  defp count_common_field_types(fields1, fields2) do
    types1 = Enum.map(fields1, & &1.type) |> MapSet.new()
    types2 = Enum.map(fields2, & &1.type) |> MapSet.new()

    MapSet.intersection(types1, types2) |> MapSet.size()
  end

  # Route Creation and Optimization

  defp create_wormhole_routes(routes) do
    Logger.info("🌀 Creating #{length(routes)} wormhole routes")

    results = Enum.map(routes, fn route ->
      case create_single_wormhole_route(route) do
        {:ok, route_id} ->
          %{route: route, status: :created, route_id: route_id}

        {:error, reason} ->
          %{route: route, status: :failed, error: reason}
      end
    end)

    successful = Enum.count(results, & &1.status == :created)
    failed = Enum.count(results, & &1.status == :failed)

    Logger.info("🌀 Wormhole creation complete: #{successful} successful, #{failed} failed")

    %{
      results: results,
      successful_count: successful,
      failed_count: failed,
      success_rate: if(length(routes) > 0, do: successful / length(routes), else: 1.0)
    }
  end

  defp create_single_wormhole_route(route) do
    source_key = convert_route_node_to_key(route.source)
    target_key = convert_route_node_to_key(route.target)

    WarpEngine.WormholeRouter.establish_wormhole(source_key, target_key, route.strength)
  end

  defp convert_route_node_to_key(node) when is_binary(node), do: node
  defp convert_route_node_to_key(node) when is_integer(node), do: "node:#{node}"
  defp convert_route_node_to_key(node) when is_atom(node), do: Atom.to_string(node)
  defp convert_route_node_to_key(node), do: "unknown:#{inspect(node)}"

  # Helper Functions

  defp generate_route_recommendations(beneficial_routes) do
    # Generate actionable recommendations for route creation
    Enum.map(beneficial_routes, fn route ->
      %{
        action: :create_wormhole,
        priority: route.priority,
        source: route.candidate.source || "unknown",
        target: route.candidate.target || "unknown",
        estimated_benefit: route.benefit_score,
        implementation_notes: generate_implementation_notes(route)
      }
    end)
  end

  defp generate_implementation_notes(route) do
    notes = []

    notes = if route.benefit_score > 0.8 do
      ["High priority - significant performance benefit expected" | notes]
    else
      notes
    end

    notes = if route.creation_cost > 0.15 do
      ["Higher creation cost - ensure adequate resources" | notes]
    else
      notes
    end

    notes
  end

  defp calculate_total_performance_gain(beneficial_routes) do
    if length(beneficial_routes) > 0 do
      total_benefit = Enum.map(beneficial_routes, & &1.benefit_score) |> Enum.sum()
      total_benefit / length(beneficial_routes)
    else
      0.0
    end
  end

  defp estimate_route_distance(_route_candidate), do: 2  # Simplified
  defp analyze_route_pattern(_route_candidate), do: :medium_frequency  # Simplified
  defp estimate_route_complexity(_route_candidate), do: :moderate  # Simplified

  defp calculate_hub_route_strength(_hub, _target), do: 0.7  # Simplified

  defp estimate_topology_performance(routes) do
    %{
      estimated_throughput_improvement: length(routes) * 0.1,
      estimated_latency_reduction: min(0.5, length(routes) * 0.05)
    }
  end

  defp estimate_maintenance_requirements(routes) do
    %{
      monitoring_overhead: length(routes) * 0.01,
      update_frequency: :weekly,
      resource_requirements: calculate_resource_requirements(routes)
    }
  end

  defp calculate_resource_requirements(routes) do
    %{
      memory_overhead_mb: length(routes) * 0.1,
      cpu_overhead_percent: min(5.0, length(routes) * 0.1)
    }
  end

  defp calculate_network_performance_metrics(creation_results) do
    %{
      network_efficiency: creation_results.success_rate,
      estimated_performance_gain: creation_results.successful_count * 0.15,
      maintenance_complexity: determine_maintenance_complexity(creation_results.successful_count)
    }
  end

  defp determine_maintenance_complexity(route_count) do
    cond do
      route_count > 50 -> :high
      route_count > 20 -> :medium
      route_count > 5 -> :low
      true -> :minimal
    end
  end

  # Placeholder functions for optimization features
  defp analyze_usage_patterns(_usage_metrics), do: %{optimization_opportunities: []}
  defp generate_optimization_recommendations(_usage_analysis), do: []
  defp apply_network_optimizations(_optimizations), do: %{routes_strengthened: 0, routes_removed: 0, performance_gain: 0.0}
end
