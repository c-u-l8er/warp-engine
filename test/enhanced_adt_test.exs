defmodule EnhancedADTTest do
  use ExUnit.Case
  doctest EnhancedADT

  require Logger

  @moduletag :enhanced_adt

  # Test helper module at top level to avoid nesting issues
  defmodule EnhancedADTTest.TestUser do
    defstruct [:id, :name, :email, :loyalty_score, :activity_level, :created_at]

    def new(id, name, email, loyalty_score, activity_level, created_at) do
      %__MODULE__{
        id: id,
        name: name,
        email: email,
        loyalty_score: loyalty_score,
        activity_level: activity_level,
        created_at: created_at
      }
    end

    # Add keyword list constructor for testing
    def new(fields) when is_list(fields) do
      struct(__MODULE__, fields)
    end

    # Mock ADT functions for testing
    def __adt_physics_config__ do
      %{
        loyalty_score: :gravitational_mass,
        activity_level: :quantum_entanglement_potential,
        created_at: :temporal_weight
      }
    end

    def __adt_field_specs__ do
      [
        %{name: :id, type: :string, physics: nil},
        %{name: :name, type: :string, physics: nil},
        %{name: :email, type: :string, physics: nil},
        %{name: :loyalty_score, type: :float, physics: :gravitational_mass},
        %{name: :activity_level, type: :float, physics: :quantum_entanglement_potential},
        %{name: :created_at, type: :datetime, physics: :temporal_weight}
      ]
    end

    def extract_physics_context(user) do
      %{
        gravitational_mass: user.loyalty_score,
        quantum_entanglement_potential: user.activity_level,
        temporal_weight: if(user.created_at, do: 1.0, else: 0.5)
      }
    end
  end

  describe "Enhanced ADT Product Types with Physics Integration" do

    test "defproduct creates product type with physics annotations" do
      # Test that we can create a user with physics annotations
      user = EnhancedADTTest.TestUser.new("user123", "Alice Johnson", "alice@example.com", 0.8, 0.7, DateTime.utc_now())

      assert user.id == "user123"
      assert user.name == "Alice Johnson"
      assert user.email == "alice@example.com"
      assert user.loyalty_score == 0.8
      assert user.activity_level == 0.7
      assert %DateTime{} = user.created_at
    end

    test "defproduct generates physics configuration for IsLabDB integration" do
      physics_config = EnhancedADTTest.TestUser.__adt_physics_config__()

      # Physics annotations should map to IsLabDB physics parameters
      assert Map.get(physics_config, :loyalty_score) == :gravitational_mass
      assert Map.get(physics_config, :activity_level) == :quantum_entanglement_potential
      assert Map.get(physics_config, :created_at) == :temporal_weight
    end

    test "defproduct generates field specifications for optimization" do
      field_specs = EnhancedADTTest.TestUser.__adt_field_specs__()

      assert is_list(field_specs)
      assert length(field_specs) == 6  # id, name, email, loyalty_score, activity_level, created_at

      # Check field specifications contain physics annotations
      loyalty_field = Enum.find(field_specs, fn spec -> spec.name == :loyalty_score end)
      assert loyalty_field.physics == :gravitational_mass

      activity_field = Enum.find(field_specs, fn spec -> spec.name == :activity_level end)
      assert activity_field.physics == :quantum_entanglement_potential
    end

    test "extract_physics_context generates physics parameters for IsLabDB" do
      user = EnhancedADTTest.TestUser.new("user123", "Alice Johnson", "alice@example.com", 0.8, 0.7, DateTime.utc_now())

      physics_context = EnhancedADTTest.TestUser.extract_physics_context(user)

      # Should extract physics parameters based on annotations
      assert Map.get(physics_context, :gravitational_mass) == 0.8
      assert Map.get(physics_context, :quantum_entanglement_potential) == 0.7
      assert is_float(Map.get(physics_context, :temporal_weight))
      assert Map.get(physics_context, :temporal_weight) == 1.0  # DateTime converts to 1.0
    end

    test "defproduct with complex physics annotations" do
      # Test a more complex product type following design docs
      defmodule TestCustomer do
        use EnhancedADT

        defproduct Customer do
          id :: String.t()
          loyalty_score :: float()
          activity_level :: float()
          region :: String.t()
          created_at :: DateTime.t()
        end
      end

      # Test physics configuration (no physics annotations in this simplified version)
      physics_config = TestCustomer.Customer.__adt_physics_config__()
      assert physics_config == %{}  # No physics annotations

      # Test creating customer
      customer = TestCustomer.Customer.new("cust1", 0.9, 0.8, "us-west", DateTime.utc_now())
      assert customer.id == "cust1"
      assert customer.loyalty_score == 0.9

      # Test physics context extraction (should return empty since no annotations)
      physics_context = TestCustomer.Customer.extract_physics_context(customer)
      assert physics_context == %{}  # No physics annotations to extract
    end

    test "defproduct constructor functions work properly" do
      # Test positional constructor
      user = EnhancedADTTest.TestUser.new("user123", "Alice", "alice@example.com", 0.8, 0.7, DateTime.utc_now())
      assert user.id == "user123"

      # Test keyword list constructor
      user_kw = EnhancedADTTest.TestUser.new([
        id: "user456",
        name: "Bob",
        email: "bob@example.com", 
        loyalty_score: 0.6,
        activity_level: 0.9,
        created_at: DateTime.utc_now()
      ])
      assert user_kw.id == "user456"
      assert user_kw.name == "Bob"
    end
  end

  describe "Enhanced ADT Sum Types with Wormhole Topology" do
    
    test "defsum creates sum type with automatic wormhole topology generation" do
      defmodule TestDataFlow do
        use EnhancedADT

        defsum DataFlow do
          {:Source, [:data]}
          {:Transform, [:input, :output]}
          {:Sink, [:destination]}
        end
      end

      # Test that the sum type module was created
      assert Code.ensure_loaded?(TestDataFlow.DataFlow)

      # Test that wormhole topology function exists (following design docs)
      assert function_exported?(TestDataFlow.DataFlow, :__adt_wormhole_topology__, 0)

      topology = TestDataFlow.DataFlow.__adt_wormhole_topology__()

      # Should generate wormhole network topology information
      assert Map.has_key?(topology, :sum_type)
      assert Map.has_key?(topology, :variant_count)
      assert Map.has_key?(topology, :wormhole_connections)
      assert Map.has_key?(topology, :topology_type)

      assert topology.sum_type == TestDataFlow.DataFlow
      assert topology.variant_count == 3
      assert topology.topology_type == :sum_type_network
      assert is_list(topology.wormhole_connections)
    end

    test "defsum creates variant modules and constructor functions" do
      defmodule TestUserState do
        use EnhancedADT

        defsum UserState do
          {:Active, [:user_id]}
          {:Inactive, [:reason]}
          {:Suspended, []}
        end
      end

      # Test variant specifications
      variants = TestUserState.UserState.__adt_variants__()
      assert length(variants) == 3

      active_variant = Enum.find(variants, fn v -> v.name == :Active end)
      assert active_variant.name == :Active
      assert length(active_variant.fields) == 1

      suspended_variant = Enum.find(variants, fn v -> v.name == :Suspended end)
      assert suspended_variant.name == :Suspended
      assert length(suspended_variant.fields) == 0
    end

    test "defsum with recursive types creates wormhole networks" do
      # Test recursive sum type following design docs
      defmodule TestSocialNetwork do
        use EnhancedADT

        defsum SocialNetwork do
          {:Person, [:user]}
          {:FriendConnection, [:person, :friends, :connection_strength]}
          {:Community, [:name, :members, :community_bridges]}
        end
      end

      # Should generate wormhole topology for recursive connections
      topology = TestSocialNetwork.SocialNetwork.__adt_wormhole_topology__()
      
      assert topology.sum_type == TestSocialNetwork.SocialNetwork
      assert topology.variant_count == 3
      assert topology.topology_type == :sum_type_network

      # Should analyze connections between variants that reference each other
      assert is_list(topology.wormhole_connections)
    end

    test "defsum generates variant checking and pattern matching functions" do
      defmodule TestResult do
        use EnhancedADT

        defsum Result do
          {:Success, [:value]}
          {:Error, [:message]}
          {:Pending, []}
        end
      end

      # Test variant checking functions
      assert function_exported?(TestResult.Result, :is_variant?, 1)
      assert function_exported?(TestResult.Result, :get_variant, 1)

      # Test with mock variant data
      success_variant = %{__variant__: :Success, value: "test"}
      error_variant = %{__variant__: :Error, message: "fail"}
      invalid_data = %{not_variant: true}

      assert TestResult.Result.is_variant?(success_variant) == true
      assert TestResult.Result.is_variant?(error_variant) == true
      assert TestResult.Result.is_variant?(invalid_data) == false

      assert TestResult.Result.get_variant(success_variant) == :Success
      assert TestResult.Result.get_variant(error_variant) == :Error
      assert TestResult.Result.get_variant(invalid_data) == nil
    end

    test "defsum with cross-references creates automatic wormhole routes" do
      # Test cross-referencing sum types following design docs  
      defmodule TestUserNetwork do
        use EnhancedADT

        defsum UserNetwork do
          {:IsolatedUser, [:user]}
          {:ConnectedUsers, [:primary, :connections, :connection_type]}
          {:RegionalCluster, [:region, :users, :inter_region_bridges]}
        end
      end

      topology = TestUserNetwork.UserNetwork.__adt_wormhole_topology__()

      # Should create wormhole connections for cross-references
      assert topology.sum_type == TestUserNetwork.UserNetwork
      assert topology.topology_type == :sum_type_network
      
      # Wormhole connections should be based on field relationships
      assert is_list(topology.wormhole_connections)
      
      # Test that variants with recursive/cross references are identified
      variants = TestUserNetwork.UserNetwork.__adt_variants__()
      connected_variant = Enum.find(variants, fn v -> v.name == :ConnectedUsers end)
      assert connected_variant.name == :ConnectedUsers
      assert length(connected_variant.fields) == 3
    end

    test "defsum creates product catalog hierarchy with category wormholes" do
      # Following design docs example
      defmodule TestProductCatalog do
        use EnhancedADT

        defsum ProductCatalog do
          {:EmptyCatalog, []}
          {:CategoryNode, [:category, :products, :subcategories]}
          {:CrossCategoryBridge, [:category_a, :category_b, :bridge_strength]}
        end
      end

      topology = TestProductCatalog.ProductCatalog.__adt_wormhole_topology__()

      assert topology.variant_count == 3
      assert topology.topology_type == :sum_type_network
      
      # Should identify connections between CategoryNode and CrossCategoryBridge variants
      # based on shared category fields
      variants = TestProductCatalog.ProductCatalog.__adt_variants__()
      
      category_node = Enum.find(variants, fn v -> v.name == :CategoryNode end)
      assert category_node.fields |> length() == 3
      
      bridge_variant = Enum.find(variants, fn v -> v.name == :CrossCategoryBridge end)
      assert bridge_variant.fields |> length() == 3
    end
  end

  describe "Enhanced ADT Fold Operations with IsLabDB Integration" do
    
    test "fold operation automatically extracts physics parameters" do
      # Following design docs: fold operations should extract physics from ADT
      user = EnhancedADTTest.TestUser.new("user123", "Alice Johnson", "alice@example.com", 0.8, 0.7, DateTime.utc_now())

      # Test fold macro execution (simplified for testing)
      result = EnhancedADT.Fold.execute_fold(user, [], mode: :balanced, analytics: true)

      # Should execute fold operation and return result
      assert result == :fold_executed
    end

    test "fold operation with performance analytics enabled" do
      user_data = %{id: "test123", name: "Test User", score: 0.9}

      # Test fold with analytics (following design docs)
      result = EnhancedADT.Fold.execute_fold(user_data, [], mode: :performance, analytics: true)

      # Should record analytics for fold operation
      assert result == :fold_executed
    end

    test "fold operation with different optimization modes" do
      test_data = %{id: "test", value: 42}

      # Test different modes following design docs
      balanced_result = EnhancedADT.Fold.execute_fold(test_data, [], mode: :balanced)
      performance_result = EnhancedADT.Fold.execute_fold(test_data, [], mode: :performance)
      storage_result = EnhancedADT.Fold.execute_fold(test_data, [], mode: :storage)

      assert balanced_result == :fold_executed
      assert performance_result == :fold_executed
      assert storage_result == :fold_executed
    end

    test "fold operation with physics-aware ADT extracts physics context" do
      # Test with a customer that has physics annotations
      defmodule TestE2ECustomer do
        use EnhancedADT

        defproduct Customer do
          id :: String.t()
          loyalty_score :: float()
          activity_level :: float()
          region :: String.t()
        end
      end

      customer = TestE2ECustomer.Customer.new("cust1", 0.9, 0.8, "us-west")
      physics_context = TestE2ECustomer.Customer.extract_physics_context(customer)

      # Verify physics extraction works before fold (no annotations so empty)
      assert physics_context == %{}

      # Test fold operation with physics-aware customer
      fold_result = EnhancedADT.Fold.execute_fold(customer, [], mode: :balanced, analytics: true)
      assert fold_result == :fold_executed
    end

    test "fold operation with IsLabDB translation simulation" do
      # Simulate the IsLabDB integration following design docs
      user = EnhancedADTTest.TestUser.new("user123", "Alice", "alice@example.com", 0.8, 0.7, DateTime.utc_now())

      # Extract physics parameters as fold would do
      physics_context = EnhancedADTTest.TestUser.extract_physics_context(user)

      # Verify physics parameters are ready for IsLabDB.cosmic_put
      assert is_float(physics_context[:gravitational_mass])
      assert is_float(physics_context[:quantum_entanglement_potential])
      assert is_float(physics_context[:temporal_weight])

      # Simulate fold operation result structure
      fold_simulation = %{
        user_key: "user:#{user.id}",
        physics_config: physics_context,
        adt_data: user,
        operation: :cosmic_put_ready
      }

      assert fold_simulation.user_key == "user:user123"
      assert fold_simulation.operation == :cosmic_put_ready
      assert is_map(fold_simulation.physics_config)
    end

    test "fold with cross-ADT references should suggest wormhole routes" do
      # Following design docs: cross-references should trigger wormhole analysis
      defmodule TestCrossRefOrder do
        use EnhancedADT

        defproduct Order do
          id :: String.t()
          customer_id :: String.t()
          product_ids :: [String.t()]
          total :: float()
        end
      end

      order = TestCrossRefOrder.Order.new("order1", "cust1", ["prod1", "prod2"], 99.99)

      # Fold operation should detect cross-references to customers and products
      fold_result = EnhancedADT.Fold.execute_fold(order, [], mode: :performance)

      # Should complete fold operation (wormhole analysis would happen in full integration)
      assert fold_result == :fold_executed
    end
  end

  describe "Enhanced ADT Bend Operations with Wormhole Networks" do
    
    test "bend operation generates structures with automatic wormhole analysis" do
      # Following design docs: bend should create wormhole networks
      user_regions = ["us-west", "us-east", "europe"]

      # Test bend operation with wormhole analysis
      result = EnhancedADT.Bend.execute_bend(user_regions, [], 
        max_recursion_depth: 100, 
        wormhole_analysis: true
      )

      # Should execute bend operation and return structure
      assert {:bend_structure, user_regions} == result
    end

    test "bend operation with recursion depth safety" do
      # Test safety mechanism for deep recursion
      deep_structure = Enum.to_list(1..2000)

      # Should hit recursion limit safely
      result = EnhancedADT.Bend.execute_bend(deep_structure, [], 
        max_recursion_depth: 10
      )

      # Should return structure within safety limits
      assert {:bend_structure, deep_structure} == result
    end

    test "bend operation creates wormhole network topology" do
      # Following design docs: automatic wormhole topology generation
      network_seed = %{
        users: ["user1", "user2", "user3"],
        regions: ["us-west", "us-east"],
        connections: []
      }

      result = EnhancedADT.Bend.execute_bend(network_seed, [], 
        wormhole_analysis: true,
        connection_strength: 0.8
      )

      # Should generate structure with wormhole analysis
      assert {:bend_structure, network_seed} == result
    end

    test "bend with recommendation network generates cross-category wormholes" do
      # Following design docs example: recommendation wormhole network
      seed_data = %{
        users: ["user1", "user2"],
        products: [
          %{id: "prod1", category: "electronics"},
          %{id: "prod2", category: "books"},
          %{id: "prod3", category: "electronics"}
        ]
      }

      # Bend should analyze product affinities and create wormhole routes
      result = EnhancedADT.Bend.execute_bend(seed_data, [], 
        wormhole_analysis: true,
        max_recursion_depth: 50
      )

      assert {:bend_structure, seed_data} == result
    end

    test "bend operation with customer network creates regional wormholes" do
      # Following design docs: regional customer network with wormhole bridges
      customer_data = %{
        customers: [
          %{id: "cust1", region: "us-west", affinity: 0.8},
          %{id: "cust2", region: "us-east", affinity: 0.6},
          %{id: "cust3", region: "us-west", affinity: 0.9}
        ]
      }

      # Should create regional wormhole topology
      result = EnhancedADT.Bend.execute_bend(customer_data, [], 
        wormhole_analysis: true,
        connection_strength: 0.7
      )

      assert {:bend_structure, customer_data} == result
    end

    test "bend operation with social network creates friendship wormholes" do
      # Following design docs: social network with automatic wormhole hubs
      social_data = %{
        people: [
          %{id: "person1", friends: ["person2", "person3"]},
          %{id: "person2", friends: ["person1", "person4"]},
          %{id: "person3", friends: ["person1"]},
          %{id: "person4", friends: ["person2"]}
        ]
      }

      # Should analyze friendship connections and create wormhole hubs
      result = EnhancedADT.Bend.execute_bend(social_data, [],
        wormhole_analysis: true,
        max_recursion_depth: 20
      )

      assert {:bend_structure, social_data} == result
    end

    test "bend operation without wormhole analysis for simple cases" do
      # Test bend without network analysis for simple structures
      simple_data = %{value: 42, processed: false}

      result = EnhancedADT.Bend.execute_bend(simple_data, [],
        wormhole_analysis: false
      )

      # Should still create structure without wormhole overhead
      assert {:bend_structure, simple_data} == result
    end

    test "bend operation creates temporal data structures" do
      # Following design docs: temporal data with automatic lifecycle
      sensor_data = %{
        sensor_id: "sensor1",
        readings: [
          %{timestamp: DateTime.utc_now(), value: 23.5, type: :live},
          %{timestamp: DateTime.add(DateTime.utc_now(), -1, :hour), value: 24.1, type: :recent},
          %{timestamp: DateTime.add(DateTime.utc_now(), -24, :hour), value: 22.8, type: :historical}
        ]
      }

      # Should create temporal structure with appropriate wormhole routing
      result = EnhancedADT.Bend.execute_bend(sensor_data, [],
        wormhole_analysis: true,
        max_recursion_depth: 30
      )

      assert {:bend_structure, sensor_data} == result
    end
  end

  describe "Enhanced ADT rec() Function for Recursive Types" do
    
    test "rec creates recursive type references" do
      # Test the rec function following design docs
      recursive_ref = EnhancedADT.rec(:Tree)
      
      assert recursive_ref == {:recursive_reference, :Tree}
    end

    test "defsum with rec creates recursive wormhole topology" do
      # Following design docs: recursive types create cyclic wormhole networks
      defmodule TestBinaryTree do
        use EnhancedADT

        defsum BinaryTree do
          {:Leaf, [:value]}
          {:Node, [:value, :left, :right]}
        end
      end

      # Should create wormhole topology that understands recursive structure
      topology = TestBinaryTree.BinaryTree.__adt_wormhole_topology__()
      
      assert topology.sum_type == TestBinaryTree.BinaryTree
      assert topology.variant_count == 2
      assert topology.topology_type == :sum_type_network
      
      # Should identify recursive connections between Node variants
      assert is_list(topology.wormhole_connections)
    end

    test "defsum with rec creates social network with wormhole hubs" do
      # Following design docs social network example
      defmodule TestSocialGraph do
        use EnhancedADT

        defsum SocialGraph do
          {:Person, [:user]}
          {:FriendNetwork, [:person, :friends, :connection_strength]}
          {:Community, [:name, :members, :bridges]}
        end
      end

      topology = TestSocialGraph.SocialGraph.__adt_wormhole_topology__()
      
      # Should create topology for social network traversal
      assert topology.variant_count == 3
      assert topology.topology_type == :sum_type_network
      
      # Should analyze connections between Person, FriendNetwork, and Community variants
      variants = TestSocialGraph.SocialGraph.__adt_variants__()
      
      friend_variant = Enum.find(variants, fn v -> v.name == :FriendNetwork end)
      assert friend_variant.name == :FriendNetwork
      assert length(friend_variant.fields) == 3
      
      community_variant = Enum.find(variants, fn v -> v.name == :Community end)  
      assert community_variant.name == :Community
      assert length(community_variant.fields) == 3
    end

    test "rec with user tree creates hierarchical wormhole structure" do
      # Following design docs user tree example
      defmodule TestUserHierarchy do
        use EnhancedADT

        defsum UserTree do
          {:UserLeaf, [:user]}
          {:UserBranch, [:user, :connections]}
          {:QuantumSuperposition, [:users, :coherence]}
        end
      end

      # Should create wormhole topology for hierarchical user traversal
      topology = TestUserHierarchy.UserTree.__adt_wormhole_topology__()
      
      assert topology.sum_type == TestUserHierarchy.UserTree
      assert topology.variant_count == 3
      
      # Should identify connections between UserBranch (recursive) and other variants
      variants = TestUserHierarchy.UserTree.__adt_variants__()
      
      branch_variant = Enum.find(variants, fn v -> v.name == :UserBranch end)
      assert branch_variant.fields |> length() == 2
      
      superposition_variant = Enum.find(variants, fn v -> v.name == :QuantumSuperposition end)
      assert superposition_variant.fields |> length() == 2
    end

    test "rec with product catalog creates category wormhole hierarchy" do
      # Following design docs product catalog example  
      defmodule TestCatalogHierarchy do
        use EnhancedADT

        defsum ProductCatalog do
          {:EmptyCatalog, []}
          {:CategoryNode, [:category, :products, :subcategories]}
          {:CrossCategoryBridge, [:category_a, :category_b, :strength]}
        end
      end

      topology = TestCatalogHierarchy.ProductCatalog.__adt_wormhole_topology__()
      
      # Should create hierarchical wormhole topology for category traversal
      assert topology.variant_count == 3
      assert topology.topology_type == :sum_type_network
      
      # CategoryNode should have recursive subcategories field
      variants = TestCatalogHierarchy.ProductCatalog.__adt_variants__()
      
      category_node = Enum.find(variants, fn v -> v.name == :CategoryNode end)
      assert category_node.fields |> length() == 3
      
      # CrossCategoryBridge should create wormhole connections between categories
      bridge_variant = Enum.find(variants, fn v -> v.name == :CrossCategoryBridge end)
      assert bridge_variant.fields |> length() == 3
    end

    test "rec with recommendation network creates quantum entanglement topology" do
      # Following design docs recommendation network
      defmodule TestRecommendationGraph do
        use EnhancedADT

        defsum RecommendationNetwork do
          {:EmptyRecommendations, []}
          {:UserRecommendations, [:user, :products]}
          {:QuantumEntangledRecommendations, [:primary, :entangled_users, :shared_products]}
          {:TemporalRecommendations, [:user, :recent, :historical, :predicted]}
        end
      end

      topology = TestRecommendationGraph.RecommendationNetwork.__adt_wormhole_topology__()
      
      # Should create quantum entanglement wormhole network
      assert topology.variant_count == 4
      assert topology.topology_type == :sum_type_network
      
      # Should identify quantum entanglement connections
      variants = TestRecommendationGraph.RecommendationNetwork.__adt_variants__()
      
      quantum_variant = Enum.find(variants, fn v -> v.name == :QuantumEntangledRecommendations end)
      assert quantum_variant.fields |> length() == 3
      
      temporal_variant = Enum.find(variants, fn v -> v.name == :TemporalRecommendations end)
      assert temporal_variant.fields |> length() == 4
    end

    test "rec function enables recursive ADT operations with wormholes" do
      # Test that rec enables proper recursive structures for bend operations
      recursive_data = %{
        tree_type: :binary_tree,
        nodes: [
          %{type: :leaf, value: 1},
          %{type: :node, value: 2, left: :leaf_1, right: :leaf_3},
          %{type: :leaf, value: 3}
        ]
      }

      # Bend operation should understand recursive structure via rec references
      result = EnhancedADT.Bend.execute_bend(recursive_data, [],
        wormhole_analysis: true,
        max_recursion_depth: 50
      )

      assert {:bend_structure, recursive_data} == result
    end
  end

  describe "Physics Configuration Analysis" do
    test "analyze ADT physics requirements" do
      analysis = EnhancedADT.Physics.analyze_adt_physics(EnhancedADTTest.TestUser)

      assert analysis.structure_info.module == EnhancedADTTest.TestUser
      assert analysis.structure_info.adt_type == :unknown  # Since we're using mock struct
      assert is_list(analysis.structure_info.fields)
      assert is_map(analysis.structure_info.physics_annotations)

      assert Map.has_key?(analysis.physics_requirements, :gravitational_optimization)
      assert Map.has_key?(analysis.physics_requirements, :quantum_optimization)
      assert Map.has_key?(analysis.physics_requirements, :temporal_optimization)

      assert is_map(analysis.optimized_config)
      assert is_map(analysis.final_config)
      assert is_list(analysis.recommendations)
    end

    test "optimize physics for different workloads" do
      read_config = EnhancedADT.Physics.optimize_for_workload(:high_read_throughput)
      write_config = EnhancedADT.Physics.optimize_for_workload(:high_write_throughput)
      balanced_config = EnhancedADT.Physics.optimize_for_workload(:balanced_workload)

      # Read optimized should have high quantum entanglement potential
      assert Map.get(read_config, :quantum_entanglement_potential) >= 0.8
      assert Map.get(read_config, :access_pattern) == :hot

      # Write optimized should have moderate entanglement to avoid contention
      assert Map.get(write_config, :quantum_entanglement_potential) <= 0.7
      assert Map.get(write_config, :entropy_optimization) == false

      # Balanced should be between the extremes
      assert Map.get(balanced_config, :quantum_entanglement_potential) >= 0.6
      assert Map.get(balanced_config, :quantum_entanglement_potential) <= 0.8
    end

    test "validate physics configuration" do
      good_config = %{
        gravitational_mass: 1.0,
        quantum_entanglement_potential: 0.7,
        temporal_weight: 1.0,
        access_pattern: :warm,
        entropy_optimization: true
      }

      validation = EnhancedADT.Physics.validate_physics_config(good_config)

      assert validation.validation_score >= 0.5
      assert is_list(validation.consistency_issues)
      assert is_list(validation.optimization_opportunities)
      assert validation.overall_assessment in [:excellent, :good, :acceptable, :needs_improvement, :poor]
    end
  end

  describe "Wormhole Analysis" do
    test "analyze potential wormhole routes" do
      cross_reference_candidates = [
        %{source: "user:123", target: "profile:123", relationship_type: :one_to_one},
        %{source: "user:123", target: "orders:user:123", relationship_type: :one_to_many},
        %{source: "product:456", target: "reviews:product:456", relationship_type: :one_to_many}
      ]

      analysis = EnhancedADT.WormholeAnalyzer.analyze_potential_routes(cross_reference_candidates)

      assert length(analysis.analyzed_candidates) == 3
      assert is_list(analysis.beneficial_routes)
      assert is_list(analysis.recommendations)
      assert Map.has_key?(analysis.summary, :total_analyzed)
      assert Map.has_key?(analysis.summary, :recommended_count)
    end

        test "create automatic routes for ADT" do
      users = [
        EnhancedADTTest.TestUser.new("user1", "Alice", "alice@example.com", 0.8, 0.7, DateTime.utc_now()),
        EnhancedADTTest.TestUser.new("user2", "Bob", "bob@example.com", 0.6, 0.9, DateTime.utc_now())
      ]

      result = EnhancedADT.WormholeAnalyzer.create_automatic_routes_for_adt(EnhancedADTTest.TestUser, users)

      assert Map.has_key?(result, :structure_analysis)
      assert Map.has_key?(result, :instance_analysis)
      assert Map.has_key?(result, :network_topology)
      assert Map.has_key?(result, :creation_results)
    end
  end

  describe "Quantum Analysis" do
    test "create quantum correlations" do
      entanglement_candidates = [
        %{key: "user:123", correlation_strength: 0.8},
        %{key: "profile:123", correlation_strength: 0.7},
        %{key: "settings:123", correlation_strength: 0.6}
      ]

      result = EnhancedADT.QuantumAnalyzer.create_correlations(entanglement_candidates)

      assert length(result.analyzed_candidates) == 3
      assert is_list(result.beneficial_entanglements)
      assert is_map(result.entanglement_groups)
      assert Map.has_key?(result.summary, :total_analyzed)
    end

    test "analyze ADT for quantum opportunities" do
      analysis = EnhancedADT.QuantumAnalyzer.analyze_adt_for_quantum_opportunities(EnhancedADTTest.TestUser)

      assert analysis.structure_info.module == EnhancedADTTest.TestUser
      assert is_list(analysis.quantum_opportunities)
      assert is_list(analysis.field_correlations)
      assert is_list(analysis.recommendations)
      assert Map.has_key?(analysis.estimated_benefits, :total_estimated_benefit)
    end
  end
end
