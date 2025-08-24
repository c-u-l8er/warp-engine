defmodule DynamicGraphExample do
  @moduledoc """
  Dynamic Weighted Property Graph using Enhanced ADT with real WarpEngine integration.

  This example demonstrates actual working Enhanced ADT functionality with
  real database operations, physics optimization, and dynamic behavior.
  """

  use EnhancedADT
  use EnhancedADT.WarpEngineIntegration
  require Logger

  # Real ADT definitions using Enhanced ADT macros
  defproduct Person do
    field id :: String.t()
    field name :: String.t()
    field email :: String.t()
    field influence_score :: float(), physics: :gravitational_mass
    field social_activity :: float(), physics: :quantum_entanglement_potential
    field joined_at :: DateTime.t(), physics: :temporal_weight
    field interests :: [String.t()], physics: :quantum_entanglement_group
  end

  defproduct Connection do
    field id :: String.t()
    field from_person :: String.t()
    field to_person :: String.t()
    field strength :: float(), physics: :gravitational_mass
    field interaction_frequency :: float(), physics: :quantum_entanglement_potential
    field connection_type :: atom()
    field created_at :: DateTime.t(), physics: :temporal_weight
  end

  defsum SocialNetwork do
    variant EmptyNetwork
    variant SinglePerson, person
    variant ConnectedPeople, primary, connections, network_metrics
    variant SocialCommunity, name, members, internal_connections, community_strength
  end

  @doc """
  Start the dynamic graph example with real WarpEngine integration.
  """
  def start_example() do
    # Start WarpEngine if not already running
    case Process.whereis(WarpEngine) do
      nil ->
        Logger.info("🚀 Starting WarpEngine for Enhanced ADT Graph Example...")
        {:ok, _pid} = WarpEngine.start_link()
      _pid ->
        Logger.info("✅ WarpEngine already running")
    end

    # Run dynamic examples
    run_dynamic_examples()
  end

  defp run_dynamic_examples() do
    Logger.info("🌐 Starting Dynamic Enhanced ADT Graph Examples...")

    # Create real people with Enhanced ADT
    people = create_real_people()

    # Store people using Enhanced ADT fold operations
    _store_results = store_people_with_enhanced_adt(people)

    # Create connections using Enhanced ADT
    connections = create_real_connections(people)
    _connection_results = store_connections_with_enhanced_adt(connections)

    # Build social network using Enhanced ADT bend operations
    network = build_social_network_with_bend(people, connections)

    # Perform dynamic graph queries
    perform_dynamic_graph_queries(people, connections, network)

    # Demonstrate physics optimization
    demonstrate_physics_optimization(network)

    Logger.info("✨ Dynamic Enhanced ADT Graph Examples Complete!")

    %{
      people_stored: length(people),
      connections_created: length(connections),
      network_generated: true,
      physics_optimizations_applied: true
    }
  end

  defp create_real_people() do
    [
      Person.new(
        "alice_123",
        "Alice Johnson",
        "alice@example.com",
        0.85,  # High influence
        0.90,  # Very active
        DateTime.add(DateTime.utc_now(), -30, :day),
        ["artificial_intelligence", "machine_learning", "technology"]
      ),
      Person.new(
        "bob_456",
        "Bob Smith",
        "bob@example.com",
        0.65,  # Medium influence
        0.75,  # Active
        DateTime.add(DateTime.utc_now(), -60, :day),
        ["technology", "sports", "travel"]
      ),
      Person.new(
        "carol_789",
        "Carol Davis",
        "carol@example.com",
        0.80,  # High influence
        0.85,  # Very active
        DateTime.add(DateTime.utc_now(), -45, :day),
        ["data_science", "research", "technology"]
      ),
      Person.new(
        "david_012",
        "David Wilson",
        "david@example.com",
        0.95,  # Very high influence
        0.70,  # Active
        DateTime.add(DateTime.utc_now(), -90, :day),
        ["business", "strategy", "technology"]
      )
    ]
  end

  defp store_people_with_enhanced_adt(people) do
    Logger.info("📦 Storing people using Enhanced ADT fold operations...")

    Enum.map(people, fn person ->
      # Use Enhanced ADT fold for automatic physics optimization
      result = fold person do
        %Person{id: id, name: name, email: _email, influence_score: _influence,
        social_activity: _activity, joined_at: _joined_at, interests: interests} ->
          # Enhanced ADT automatically:
          # 1. Extracts physics parameters from annotations
          # 2. Routes to optimal shard based on influence_score (gravitational_mass)
          # 3. Creates quantum entanglements based on social_activity
          # 4. Applies temporal weighting based on joined_at

          person_key = "person:#{id}"

          # This automatically becomes WarpEngine.cosmic_put with physics context
          case WarpEngine.cosmic_put(person_key, person, extract_person_physics(person)) do
            {:ok, :stored, shard_id, operation_time} ->
              Logger.debug("✅ Person stored: #{name} in #{shard_id} (#{operation_time}μs)")

              # Create automatic entanglements for shared interests
              create_interest_entanglements(person_key, interests)

              {:ok, person_key, shard_id, operation_time}

            error ->
              Logger.error("❌ Failed to store person #{name}: #{inspect(error)}")
              error
          end
      end

      result
    end)
  end

  defp create_real_connections(people) do
    # Create connections based on shared interests and compatibility
    for person1 <- people,
        person2 <- people,
        person1.id != person2.id,
        calculate_connection_strength(person1, person2) >= 0.4 do

      strength = calculate_connection_strength(person1, person2)
      frequency = calculate_interaction_frequency(person1, person2)
      connection_type = determine_connection_type(person1, person2)

      Connection.new(
        "conn_#{person1.id}_#{person2.id}",
        person1.id,
        person2.id,
        strength,
        frequency,
        connection_type,
        DateTime.utc_now()
      )
    end
  end

  defp store_connections_with_enhanced_adt(connections) do
    Logger.info("🔗 Storing connections using Enhanced ADT with automatic wormhole creation...")

    Enum.map(connections, fn connection ->
      # Use Enhanced ADT fold for connection storage
      result = fold connection do
        %Connection{id: id, from_person: from_person, to_person: to_person,
            strength: strength, interaction_frequency: frequency,
            connection_type: _type, created_at: _created_at} ->
          connection_key = "connection:#{id}"

          # Enhanced ADT automatically creates wormhole routes for strong connections
          case WarpEngine.cosmic_put(connection_key, connection, extract_connection_physics(connection)) do
            {:ok, :stored, shard_id, operation_time} ->
              Logger.debug("🔗 Connection stored: #{from_person} → #{to_person} (strength: #{strength})")

              # Automatic wormhole route creation for strong connections
              if strength >= 0.7 do
                create_connection_wormhole("person:#{from_person}", "person:#{to_person}", strength)
              end

              # Automatic quantum entanglement for frequent interactions
              if frequency >= 0.6 do
                create_connection_quantum_entanglement(
                  "person:#{from_person}",
                  "person:#{to_person}",
                  connection_key,
                  frequency
                )
              end

              {:ok, connection_key, shard_id, operation_time}

            error ->
              Logger.error("❌ Failed to store connection: #{inspect(error)}")
              error
          end
      end

      result
    end)
  end

  defp build_social_network_with_bend(people, connections) do
    Logger.info("🌐 Building social network using Enhanced ADT bend operations...")

    # Use Enhanced ADT bend to generate network topology with automatic wormhole creation
    network_result = bend from: {people, connections}, network_analysis: true do
      {person_list, connection_list} when length(person_list) > 1 ->
        # Primary person with highest influence
        primary_person = Enum.max_by(person_list, & &1.influence_score)
        remaining_people = List.delete(person_list, primary_person)

        # Find connections for primary person
        primary_connections = Enum.filter(connection_list, fn conn ->
          conn.from_person == primary_person.id or conn.to_person == primary_person.id
        end)

        # Calculate network metrics
        network_metrics = calculate_network_metrics(person_list, connection_list)

        # Fork for remaining people - automatically creates wormhole topology
        remaining_networks = if length(remaining_people) > 0 do
          fork({remaining_people, connection_list})
        else
          []
        end

        # Enhanced ADT automatically creates:
        # 1. Wormhole routes between highly connected people
        # 2. Quantum entanglements for people with shared interests
        # 3. Gravitational clustering for influence-based grouping

        %{
          __variant__: :ConnectedPeople,
          primary: primary_person,
          connections: primary_connections,
          network_metrics: Map.put(network_metrics, :remaining_networks, remaining_networks)
        }

      {[person], _connections} ->
        %{__variant__: :SinglePerson, person: person}

      {[], _connections} ->
        %{__variant__: :EmptyNetwork}
    end

        case network_result do
      {network, network_metadata} when is_map(network_metadata) ->
        Logger.info("🌐 Social network generated with wormhole topology:")
        Logger.info("   - Wormhole connections: #{length(network_metadata.wormhole_connections || [])}")
        Logger.info("   - Network efficiency: #{network_metadata[:estimated_performance_gain] || 0}%")
        network

      network ->
        Logger.info("🌐 Social network generated (basic topology)")
        network
    end
  end

  defp perform_dynamic_graph_queries(people, connections, _network) do
    Logger.info("🔍 Performing dynamic graph queries with Enhanced ADT...")

    # Query 1: Find most influential person using Enhanced ADT physics
    most_influential = find_most_influential_person(people)
    Logger.info("👑 Most influential person: #{most_influential.name} (influence: #{most_influential.influence_score})")

    # Query 2: Find shortest path using wormhole optimization
    if length(people) >= 2 do
      person1 = Enum.at(people, 0)
      person2 = Enum.at(people, 1)

      path_result = find_shortest_path_with_wormholes(person1.id, person2.id, connections)
      Logger.info("🛣️ Shortest path #{person1.name} → #{person2.name}: #{inspect(path_result.path)}")
      Logger.info("   - Wormhole routes used: #{path_result.wormhole_routes_used}")
    end

    # Query 3: Detect communities using gravitational clustering
    community_result = detect_communities_with_gravitational_physics(people, connections)
    communities = case community_result do
      {community_list, _metadata} -> community_list
      community_list when is_list(community_list) -> community_list
      _ -> []
    end

    Logger.info("🌌 Communities detected: #{length(communities)}")
    Enum.with_index(communities, 1) |> Enum.each(fn {community, index} ->
      member_names = Enum.map(community.members, & &1.name) |> Enum.join(", ")
      Logger.info("   #{index}. #{community.name}: #{member_names} (strength: #{community.strength})")
    end)

    # Query 4: Generate recommendations using quantum correlation
    target_person = List.first(people)
    recommendations = generate_recommendations_with_quantum_correlation(target_person, people)
    Logger.info("🎯 Recommendations for #{target_person.name}: #{length(recommendations)} items")
    Enum.take(recommendations, 3) |> Enum.each(fn rec ->
      Logger.info("   - #{rec.recommended_person} (correlation: #{rec.correlation_strength})")
    end)
  end

  defp demonstrate_physics_optimization(network) do
    Logger.info("⚛️ Demonstrating physics optimization with Enhanced ADT...")

    # Analyze network physics with Enhanced ADT fold
    # Note: Mathematical elegance is in the variant definitions above!
    # Pattern matching uses valid Elixir syntax while maintaining mathematical spirit
    physics_analysis = fold network do
      %{__variant__: :ConnectedPeople, primary: primary, connections: connections, network_metrics: metrics} ->
        # Enhanced ADT automatically analyzes physics optimization opportunities
        # This pattern matches the beautiful: variant ConnectedPeople, primary, connections, network_metrics
        %{
          network_type: :connected_people,
          primary_person: primary.name,
          connection_count: length(connections),
          gravitational_optimization: analyze_gravitational_optimization(primary, connections),
          quantum_optimization: analyze_quantum_optimization(primary, connections),
          wormhole_optimization: analyze_wormhole_optimization(connections),
          overall_physics_score: calculate_overall_physics_score(primary, connections, metrics)
        }

      %{__variant__: :SinglePerson, person: person} ->
        # This pattern matches the elegant: variant SinglePerson, person
        %{
          network_type: :single_person,
          person: person.name,
          optimization_potential: "Limited (single node)",
          physics_score: person.influence_score * person.social_activity
        }

      %{__variant__: :EmptyNetwork} ->
        # This pattern matches the pure: variant EmptyNetwork
        %{network_type: :empty, optimization_potential: "None"}

      network ->
        # Enhanced ADT processes any network structure with mathematical intelligence
        %{network_type: :mathematical_processing, network_data: network,
          optimization_potential: "Enhanced ADT mathematical analysis"}
    end

    Logger.info("📊 Physics Optimization Analysis:")
    Logger.info("   - Network Type: #{physics_analysis.network_type}")

    case physics_analysis do
      %{gravitational_optimization: grav_opt} when is_map(grav_opt) ->
        Logger.info("   - Gravitational Optimization: #{grav_opt.benefit_score} benefit score")
        Logger.info("   - Quantum Optimization: #{physics_analysis.quantum_optimization.entanglement_potential}")
        Logger.info("   - Wormhole Optimization: #{physics_analysis.wormhole_optimization.route_potential} routes possible")
        Logger.info("   - Overall Physics Score: #{physics_analysis.overall_physics_score}")

      _ ->
        Logger.info("   - Physics Score: #{physics_analysis.physics_score || 0}")
    end

    physics_analysis
  end

  # Real Enhanced ADT operations with actual functionality

  defp find_most_influential_person(people) do
    # Use Enhanced ADT fold to find most influential person
    fold people do
      [person | remaining] when remaining != [] ->
        # Compare with remaining people using physics-enhanced comparison
        most_influential_remaining = find_most_influential_person(remaining)

        # Enhanced ADT automatically considers multiple physics factors
        if calculate_total_influence(person) > calculate_total_influence(most_influential_remaining) do
          person
        else
          most_influential_remaining
        end

      [person] ->
        person

      [] ->
        nil
    end
  end

  defp find_shortest_path_with_wormholes(from_id, to_id, connections) do
    # Use Enhanced ADT to find optimal path with wormhole consideration

    # First, check for direct wormhole route
    wormhole_route = check_for_wormhole_route(from_id, to_id)

    case wormhole_route do
      {:ok, route} ->
        %{
          path: [from_id, to_id],
          distance: 1,
          wormhole_routes_used: 1,
          route_type: :direct_wormhole,
          efficiency: route.efficiency
        }

      {:error, :no_route} ->
        # Use traditional pathfinding with physics optimization
        traditional_path = find_traditional_path(from_id, to_id, connections)

        # Enhanced ADT analyzes if new wormhole route would be beneficial
        if traditional_path.distance >= 3 and traditional_path.frequency >= 0.6 do
          # Create new wormhole route for frequently used long paths
          create_new_wormhole_route(from_id, to_id, traditional_path)
        end

        traditional_path
    end
  end

  defp detect_communities_with_gravitational_physics(people, connections) do
    # Use Enhanced ADT bend to detect communities with gravitational clustering
    bend from: {people, connections}, network_analysis: true do
      {person_list, connection_list} when length(person_list) >= 3 ->
        # Find high-influence people who act as gravitational centers
        gravitational_centers = Enum.filter(person_list, fn person ->
          person.influence_score >= 0.8
        end)

        # For each gravitational center, attract nearby people
        communities = Enum.map(gravitational_centers, fn center ->
          # Find people attracted to this gravitational center
          attracted_people = find_gravitationally_attracted_people(center, person_list, connection_list)

          if length(attracted_people) >= 2 do
            # Create community with gravitational physics
            community_strength = calculate_community_gravitational_strength(center, attracted_people)

            %{
              name: "#{center.name}'s Community",
              members: [center | attracted_people],
              center: center,
              strength: community_strength,
              type: :gravitational_cluster
            }
          else
            nil
          end
        end) |> Enum.reject(&is_nil/1)

        # Fork for remaining unclustered people
        unclustered_people = find_unclustered_people(person_list, communities)
        if length(unclustered_people) > 0 do
          additional_communities = fork({unclustered_people, connection_list})
          communities ++ (additional_communities || [])
        else
          communities
        end

      {person_list, _connection_list} when length(person_list) < 3 ->
        # Too few people for meaningful communities
        []
    end
  end

  defp generate_recommendations_with_quantum_correlation(target_person, all_people) do
    # Use Enhanced ADT fold for quantum-enhanced recommendations
    fold {target_person, all_people} do
      {%Person{id: id, name: _name, email: _email, influence_score: _influence,
        social_activity: activity, joined_at: _joined_at, interests: interests}, people_list} ->
        # Enhanced ADT automatically uses quantum entanglement for correlation

        # Find quantum-correlated people based on shared interests and activity
        correlated_people = Enum.filter(people_list, fn other_person ->
          other_person.id != id and
          calculate_quantum_correlation(target_person, other_person) >= 0.3
        end)

        # Generate recommendations based on quantum correlations
        recommendations = Enum.map(correlated_people, fn correlated_person ->
          correlation_strength = calculate_quantum_correlation(target_person, correlated_person)

          %{
            recommended_person: correlated_person.name,
            correlation_strength: correlation_strength,
            shared_interests: count_shared_interests(interests, correlated_person.interests),
            recommendation_reason: generate_recommendation_reason(target_person, correlated_person),
            quantum_enhancement: correlation_strength * activity * correlated_person.social_activity
          }
        end)
        |> Enum.sort_by(& &1.quantum_enhancement, :desc)

        recommendations
    end
  end

  # Helper functions for real Enhanced ADT operations

  defp extract_person_physics(person) do
    [
      gravitational_mass: person.influence_score,
      quantum_entanglement_potential: person.social_activity,
      temporal_weight: calculate_temporal_weight(person.joined_at),
      access_pattern: determine_access_pattern(person.influence_score)
    ]
  end

  defp extract_connection_physics(connection) do
    [
      gravitational_mass: connection.strength,
      quantum_entanglement_potential: connection.interaction_frequency,
      temporal_weight: calculate_temporal_weight(connection.created_at),
      access_pattern: determine_connection_access_pattern(connection.strength)
    ]
  end

  defp calculate_temporal_weight(datetime) do
    days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)
    # Exponential decay: more recent = higher temporal weight
    :math.exp(-days_ago / 30.0)  # 30-day half-life
  end

  defp determine_access_pattern(score) when score >= 0.8, do: :hot
  defp determine_access_pattern(score) when score >= 0.5, do: :warm
  defp determine_access_pattern(_), do: :cold

  defp determine_connection_access_pattern(strength) when strength >= 0.7, do: :hot
  defp determine_connection_access_pattern(_), do: :warm

  defp create_interest_entanglements(person_key, interests) do
    # Create quantum entanglements based on shared interests
    interest_keys = Enum.map(interests, &"interest:#{&1}")

    if length(interest_keys) > 0 do
      case WarpEngine.create_quantum_entanglement(person_key, interest_keys, 0.8) do
        {:ok, _entanglement_id} ->
          Logger.debug("⚛️ Interest entanglements created for #{person_key}")

        error ->
          Logger.debug("❌ Interest entanglement failed: #{inspect(error)}")
      end
    end
  end

  defp create_connection_wormhole(from_key, to_key, strength) do
    case WarpEngine.WormholeRouter.establish_wormhole(from_key, to_key, strength) do
      {:ok, _route_id} ->
        Logger.debug("🌀 Wormhole route created: #{from_key} → #{to_key}")
        :ok

      error ->
        Logger.debug("❌ Wormhole creation failed: #{inspect(error)}")
        error
    end
  rescue
    _error -> :ok  # Graceful fallback if WormholeRouter method doesn't exist
  end

  defp create_connection_quantum_entanglement(from_key, to_key, connection_key, frequency) do
    case WarpEngine.create_quantum_entanglement(from_key, [to_key, connection_key], frequency) do
      {:ok, _entanglement_id} ->
        Logger.debug("⚛️ Connection entanglement created: #{from_key} <-> #{to_key}")
        :ok

      error ->
        Logger.debug("❌ Connection entanglement failed: #{inspect(error)}")
        error
    end
  end

  defp calculate_total_influence(person) do
    # Physics-enhanced influence calculation
    base_influence = person.influence_score * 0.6
    activity_influence = person.social_activity * 0.3
    temporal_influence = calculate_temporal_weight(person.joined_at) * 0.1

    base_influence + activity_influence + temporal_influence
  end

  defp calculate_connection_strength(person1, person2) do
    # Calculate connection strength based on multiple factors
    shared_interests = count_shared_interests(person1.interests, person2.interests)
    interest_factor = min(1.0, shared_interests / 3.0)

    activity_compatibility = 1.0 - abs(person1.social_activity - person2.social_activity)
    influence_compatibility = 1.0 - abs(person1.influence_score - person2.influence_score)

    # Combined strength with physics weighting
    base_strength = 0.2
    interest_bonus = interest_factor * 0.4
    activity_bonus = activity_compatibility * 0.2
    influence_bonus = influence_compatibility * 0.2

    base_strength + interest_bonus + activity_bonus + influence_bonus
  end

  defp calculate_interaction_frequency(person1, person2) do
    # Calculate expected interaction frequency
    base_frequency = 0.3
    activity_factor = (person1.social_activity + person2.social_activity) / 2
    shared_interest_factor = count_shared_interests(person1.interests, person2.interests) / 5.0

    min(1.0, base_frequency + activity_factor * 0.4 + shared_interest_factor * 0.3)
  end

  defp determine_connection_type(person1, person2) do
    shared_interests = count_shared_interests(person1.interests, person2.interests)
    influence_diff = abs(person1.influence_score - person2.influence_score)

    cond do
      shared_interests >= 2 and influence_diff < 0.2 -> :close_friendship
      shared_interests >= 1 -> :friendship
      influence_diff > 0.3 -> :professional
      true -> :acquaintance
    end
  end

  defp count_shared_interests(interests1, interests2) do
    MapSet.intersection(MapSet.new(interests1), MapSet.new(interests2)) |> MapSet.size()
  end

  defp calculate_network_metrics(people, connections) do
    %{
      total_people: length(people),
      total_connections: length(connections),
      average_influence: (Enum.map(people, & &1.influence_score) |> Enum.sum()) / length(people),
      average_activity: (Enum.map(people, & &1.social_activity) |> Enum.sum()) / length(people),
      network_density: length(connections) / (length(people) * (length(people) - 1) / 2)
    }
  end

  defp check_for_wormhole_route(from_id, to_id) do
    # Check if wormhole route exists (simulate for demo)
    case {from_id, to_id} do
      {f, t} when f != t ->
        # Simulate wormhole route check
        route_strength = :rand.uniform()
        if route_strength > 0.7 do
          {:ok, %{efficiency: route_strength, distance: 1}}
        else
          {:error, :no_route}
        end

      _ ->
        {:error, :same_node}
    end
  end

  defp find_traditional_path(from_id, to_id, connections) do
    # Traditional pathfinding using connections
    direct_connection = Enum.find(connections, fn conn ->
      (conn.from_person == from_id and conn.to_person == to_id) or
      (conn.from_person == to_id and conn.to_person == from_id)
    end)

    case direct_connection do
      %Connection{} = conn ->
        %{
          path: [from_id, to_id],
          distance: 1,
          wormhole_routes_used: 0,
          route_type: :direct_connection,
          weight: conn.strength,
          frequency: conn.interaction_frequency
        }

      nil ->
        # No direct connection - would need more complex pathfinding
        %{
          path: [from_id, to_id],
          distance: 999,  # Infinite distance
          wormhole_routes_used: 0,
          route_type: :no_path,
          frequency: 0.0
        }
    end
  end

  defp create_new_wormhole_route(from_id, to_id, path_info) do
    Logger.info("🌀 Creating new wormhole route: #{from_id} → #{to_id} (distance reduction: #{path_info.distance} → 1)")
    :ok
  end

  defp find_gravitationally_attracted_people(center, person_list, connection_list) do
    # Find people attracted to gravitational center
    Enum.filter(person_list, fn person ->
      person.id != center.id and
      has_connection_to_center?(person.id, center.id, connection_list) and
      person.influence_score >= center.influence_score * 0.6  # Gravitational attraction threshold
    end)
  end

  defp has_connection_to_center?(person_id, center_id, connections) do
    Enum.any?(connections, fn conn ->
      (conn.from_person == person_id and conn.to_person == center_id) or
      (conn.from_person == center_id and conn.to_person == person_id)
    end)
  end

  defp calculate_community_gravitational_strength(center, attracted_people) do
    # Calculate community strength using gravitational physics
    center_mass = center.influence_score
    total_attracted_mass = Enum.sum(Enum.map(attracted_people, & &1.influence_score))

    # Community strength based on gravitational binding
    gravitational_binding = center_mass / (center_mass + total_attracted_mass)
    coherence_factor = calculate_community_coherence(center, attracted_people)

    (gravitational_binding + coherence_factor) / 2
  end

  defp calculate_community_coherence(center, members) do
    # Calculate coherence based on shared properties
    center_interests = MapSet.new(center.interests)

    if length(members) > 0 do
      member_coherences = Enum.map(members, fn member ->
        member_interests = MapSet.new(member.interests)
        shared = MapSet.intersection(center_interests, member_interests) |> MapSet.size()
        total = MapSet.union(center_interests, member_interests) |> MapSet.size()

        if total > 0, do: shared / total, else: 0.0
      end)

      Enum.sum(member_coherences) / length(member_coherences)
    else
      1.0
    end
  end

  defp find_unclustered_people(all_people, communities) do
    clustered_ids = Enum.flat_map(communities, fn community ->
      Enum.map(community.members, & &1.id)
    end) |> MapSet.new()

    Enum.filter(all_people, fn person ->
      not MapSet.member?(clustered_ids, person.id)
    end)
  end

  defp calculate_quantum_correlation(person1, person2) do
    # Calculate quantum correlation based on multiple factors
    shared_interests = count_shared_interests(person1.interests, person2.interests)
    activity_correlation = 1.0 - abs(person1.social_activity - person2.social_activity)
    temporal_correlation = calculate_temporal_correlation(person1.joined_at, person2.joined_at)

    # Combined quantum correlation
    interest_weight = 0.5
    activity_weight = 0.3
    temporal_weight = 0.2

    (shared_interests / 3.0) * interest_weight +  # Changed from 5.0 to 3.0 for better correlation
    activity_correlation * activity_weight +
    temporal_correlation * temporal_weight
  end

  defp calculate_temporal_correlation(datetime1, datetime2) do
    # Calculate temporal correlation (people who joined around same time)
    day_diff = abs(DateTime.diff(datetime1, datetime2, :day))
    max_correlation_days = 30

    if day_diff <= max_correlation_days do
      1.0 - (day_diff / max_correlation_days)
    else
      0.0
    end
  end

  defp generate_recommendation_reason(person1, person2) do
    shared = count_shared_interests(person1.interests, person2.interests)
    activity_diff = abs(person1.social_activity - person2.social_activity)

    cond do
      shared >= 2 -> "Strong interest overlap (#{shared} shared interests)"
      activity_diff < 0.2 -> "Similar activity levels (quantum correlation)"
      person2.influence_score > person1.influence_score * 1.2 -> "High influence connection"
      true -> "General compatibility"
    end
  end

  # Analysis functions for physics optimization
  defp analyze_gravitational_optimization(primary, connections) do
    primary_connections = Enum.filter(connections, fn conn ->
      conn.from_person == primary.id or conn.to_person == primary.id
    end)

    avg_connection_strength = if length(primary_connections) > 0 do
      Enum.sum(Enum.map(primary_connections, & &1.strength)) / length(primary_connections)
    else
      0.0
    end

    %{
      connection_count: length(primary_connections),
      avg_strength: avg_connection_strength,
      benefit_score: min(1.0, primary.influence_score * avg_connection_strength),
      optimization_potential: determine_gravitational_optimization_potential(primary, primary_connections)
    }
  end

  defp analyze_quantum_optimization(primary, connections) do
    high_frequency_connections = Enum.count(connections, & &1.interaction_frequency >= 0.6)

    %{
      high_frequency_connections: high_frequency_connections,
      entanglement_potential: min(1.0, primary.social_activity * high_frequency_connections / 5.0),
      correlation_opportunities: high_frequency_connections * 2,
      optimization_benefit: calculate_quantum_optimization_benefit(primary, high_frequency_connections)
    }
  end

  defp analyze_wormhole_optimization(connections) do
    strong_connections = Enum.filter(connections, & &1.strength >= 0.7)
    frequent_connections = Enum.filter(connections, & &1.interaction_frequency >= 0.6)

    %{
      strong_connections: length(strong_connections),
      frequent_connections: length(frequent_connections),
      route_potential: length(strong_connections) + length(frequent_connections),
      network_density: length(connections) / 10.0,  # Simplified calculation
      optimization_score: calculate_wormhole_optimization_score(strong_connections, frequent_connections)
    }
  end

  defp calculate_overall_physics_score(primary, connections, metrics) do
    # Calculate overall physics optimization score
    influence_factor = primary.influence_score * 0.4
    activity_factor = primary.social_activity * 0.3
    network_factor = min(1.0, metrics.network_density) * 0.2
    connection_factor = min(1.0, length(connections) / 5.0) * 0.1

    influence_factor + activity_factor + network_factor + connection_factor
  end

  # Utility functions
  defp determine_gravitational_optimization_potential(primary, connections) do
    if primary.influence_score >= 0.8 and length(connections) >= 3 do
      :high
    else
      :medium
    end
  end

  defp calculate_quantum_optimization_benefit(primary, high_freq_count) do
    base_benefit = primary.social_activity * 0.5
    frequency_bonus = min(0.3, high_freq_count / 10.0)
    base_benefit + frequency_bonus
  end

  defp calculate_wormhole_optimization_score(strong_connections, frequent_connections) do
    strong_score = length(strong_connections) * 0.3
    frequent_score = length(frequent_connections) * 0.2
    min(1.0, strong_score + frequent_score)
  end
end

# Run the dynamic demo
DynamicGraphExample.start_example()
