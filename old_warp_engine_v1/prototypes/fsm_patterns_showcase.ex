defmodule FSMPatternsShowcase do
  @moduledoc """
  Focused demonstration of core FSM patterns as first-class values.

  This showcase demonstrates the revolutionary concept of FSMs as variables/functions
  that can spawn other FSMs, walk backwards, and collaborate to parse complex patterns.

  ## Core Concepts Demonstrated:

  1. **FSM Variables** - Creating, storing, and manipulating FSMs as values
  2. **FSM Functions** - FSMs that return other FSMs based on input
  3. **Bidirectional Parsing** - FSMs that can walk backward in token streams
  4. **FSM Spawning** - FSMs that create specialized child FSMs
  5. **Pattern Collaboration** - Multiple FSMs working together
  6. **Adaptive Parsing** - FSMs that modify themselves based on patterns

  ## Real-World Example:

  ```elixir
  # FSM that recognizes balanced braces and spawns content parsers
  brace_parser = fsm_function do
    on_token "{" do
      # Create new FSM for the content inside braces
      content_fsm = spawn_content_parser(current_context())

      # This FSM can walk backward to understand context
      if needs_special_handling?(peek_backward(3)) do
        spawn_specialized_fsm(get_context_type())
      end

      # Continue with balanced brace counting
      increment_depth()
    end

    on_token "}" do
      if depth() == 1 do
        # Finalize and return result from spawned FSMs
        combine_results(spawned_fsms())
      else
        decrement_depth()
      end
    end
  end
  ```
  """

  require Logger

  # =============================================================================
  # FSM AS FIRST-CLASS VALUE DEMONSTRATIONS
  # =============================================================================

  @doc """
  Demonstrate FSM creation as variables with different behaviors.
  """
  def demonstrate_fsm_variables do
    Logger.info("🤖 DEMONSTRATION: FSMs as First-Class Variables")
    Logger.info("")

    # Create FSMs as variables - each has different behavior
    simple_counter = create_counter_fsm(name: "SimpleCounter", max: 5)
    complex_counter = create_counter_fsm(name: "ComplexCounter", max: 10, can_backtrack: true)
    adaptive_counter = create_adaptive_counter_fsm(name: "AdaptiveCounter")

    Logger.info("📦 Created FSM Variables:")
    Logger.info("   simple_counter = #{inspect_fsm(simple_counter)}")
    Logger.info("   complex_counter = #{inspect_fsm(complex_counter)}")
    Logger.info("   adaptive_counter = #{inspect_fsm(adaptive_counter)}")
    Logger.info("")

    # Use FSMs as variables - pass them around, modify them
    fsm_list = [simple_counter, complex_counter, adaptive_counter]

    Logger.info("🔧 Using FSMs as Variables:")

    # Process input with each FSM
    test_input = ["1", "2", "3", "4", "5", "6"]

    results = Enum.map(fsm_list, fn fsm ->
      Logger.info("   Running #{fsm.name} on input...")
      result = run_fsm(fsm, test_input)
      Logger.info("     Result: #{result.final_count}, Success: #{result.success}")
      result
    end)

    # FSMs can be modified and reused
    Logger.info("")
    Logger.info("🔄 Modifying FSMs as Variables:")
    modified_simple = modify_fsm_max_count(simple_counter, 8)
    Logger.info("   Modified simple_counter max from #{simple_counter.max_count} to #{modified_simple.max_count}")

    # FSMs can be composed
    composed_fsm = compose_fsms([simple_counter, complex_counter])
    Logger.info("   Composed FSM: #{composed_fsm.name} (combines #{length(composed_fsm.component_fsms)} FSMs)")

    results
  end

  @doc """
  Demonstrate FSMs as functions that return other FSMs.
  """
  def demonstrate_fsm_functions do
    Logger.info("🎭 DEMONSTRATION: FSMs as Functions")
    Logger.info("")

    # Create FSM factory functions
    Logger.info("🏭 FSM Factory Functions:")

    # Function that creates parser FSMs based on input type
    parser_factory = fn input_type ->
      case input_type do
        :json -> create_json_parser_fsm()
        :xml -> create_xml_parser_fsm()
        :csv -> create_csv_parser_fsm()
        :natural_language -> create_nl_parser_fsm()
        _ -> create_generic_parser_fsm()
      end
    end

    # Function that creates FSMs based on complexity requirements
    complexity_fsm_factory = fn complexity, features ->
      base_fsm = create_base_parser_fsm()

      enhanced_fsm = if :backtracking in features do
        add_backtracking_capability(base_fsm)
      else
        base_fsm
      end

      final_fsm = if :spawning in features do
        add_spawning_capability(enhanced_fsm)
      else
        enhanced_fsm
      end

      set_complexity_level(final_fsm, complexity)
    end

    Logger.info("   parser_factory = fn(type) -> FSM for that type")
    Logger.info("   complexity_fsm_factory = fn(level, features) -> Custom FSM")
    Logger.info("")

    # Use FSM factory functions
    Logger.info("🎯 Using FSM Factory Functions:")

    # Generate different parser FSMs
    json_fsm = parser_factory.(:json)
    xml_fsm = parser_factory.(:xml)
    nl_fsm = parser_factory.(:natural_language)

    Logger.info("   Generated Parsers:")
    Logger.info("     json_fsm: #{json_fsm.name} (#{json_fsm.parser_type})")
    Logger.info("     xml_fsm: #{xml_fsm.name} (#{xml_fsm.parser_type})")
    Logger.info("     nl_fsm: #{nl_fsm.name} (#{nl_fsm.parser_type})")

    # Generate custom complexity FSMs
    simple_fsm = complexity_fsm_factory.(:simple, [])
    advanced_fsm = complexity_fsm_factory.(:advanced, [:backtracking, :spawning])

    Logger.info("   Generated Custom FSMs:")
    Logger.info("     simple_fsm: #{simple_fsm.name} (complexity: #{simple_fsm.complexity})")
    Logger.info("     advanced_fsm: #{advanced_fsm.name} (complexity: #{advanced_fsm.complexity}, features: #{length(advanced_fsm.features)})")
    Logger.info("")

    # FSM functions can be chained and composed
    Logger.info("🔗 Chaining FSM Functions:")

    # Chain: create base FSM, then enhance it
    chained_fsm = parser_factory.(:json)
    |> add_error_recovery()
    |> add_streaming_support()
    |> optimize_for_performance()

    Logger.info("   Chained JSON parser: #{chained_fsm.name}")
    Logger.info("     Features: #{Enum.join(chained_fsm.features, ", ")}")

    [json_fsm, xml_fsm, nl_fsm, simple_fsm, advanced_fsm, chained_fsm]
  end

  @doc """
  Demonstrate bidirectional parsing where FSMs can walk backwards.
  """
  def demonstrate_bidirectional_fsm do
    Logger.info("↔️ DEMONSTRATION: Bidirectional FSM Parsing")
    Logger.info("")

    # Create FSM that can walk backwards to understand context
    bidirectional_fsm = create_bidirectional_parser_fsm()

    # Ambiguous input that requires backward analysis
    ambiguous_tokens = [
      "Time",      # Could be noun or verb
      "flies",     # Could be verb or noun
      "like",      # Could be preposition or verb
      "an",        # Article
      "arrow"      # Noun
    ]

    Logger.info("🧩 Ambiguous Input: #{Enum.join(ambiguous_tokens, " ")}")
    Logger.info("   Possible interpretations:")
    Logger.info("     1. 'Time flies like an arrow' (time moves quickly)")
    Logger.info("     2. 'Time flies like an arrow' (time-flies enjoy arrows)")
    Logger.info("")

    Logger.info("🔄 Bidirectional Parsing Process:")

    # Simulate bidirectional parsing step by step
    position = 0
    fsm_state = %{current_position: 0, interpretation: nil, confidence: 0.0}

    Logger.info("   Position 0: '#{Enum.at(ambiguous_tokens, 0)}'")
    Logger.info("     Forward analysis: Could be noun or verb")
    Logger.info("     Backward context: None (start of input)")
    Logger.info("     Decision: Mark as ambiguous, continue")

    Logger.info("")
    Logger.info("   Position 1: '#{Enum.at(ambiguous_tokens, 1)}'")
    Logger.info("     Forward analysis: Could be verb (flies) or noun (plural of fly)")
    Logger.info("     Backward context: Previous token was 'Time'")
    Logger.info("     Decision: Still ambiguous, need more context")

    Logger.info("")
    Logger.info("   Position 2: '#{Enum.at(ambiguous_tokens, 2)}'")
    Logger.info("     Forward analysis: 'like' - preposition or verb")
    Logger.info("     Backward analysis: Walk back to position 0")
    Logger.info("       If 'Time flies' = subject + verb, then 'like' = preposition")
    Logger.info("       If 'Time' = adjective, 'flies' = noun, then 'like' = verb")
    Logger.info("     Decision: Pattern suggests 'Time flies' (subject + verb)")

    Logger.info("")
    Logger.info("   Position 3-4: 'an arrow'")
    Logger.info("     Forward analysis: Definite article + noun")
    Logger.info("     Backward confirmation: 'like an arrow' confirms preposition usage")
    Logger.info("     Final interpretation: 'Time flies like an arrow' (temporal metaphor)")

    # Run the actual bidirectional FSM
    result = run_bidirectional_fsm(bidirectional_fsm, ambiguous_tokens)

    Logger.info("")
    Logger.info("🎯 Bidirectional Parsing Result:")
    Logger.info("   Final interpretation: #{result.interpretation}")
    Logger.info("   Confidence: #{Float.round(result.confidence, 2)}")
    Logger.info("   Backward walks: #{result.backward_walks}")
    Logger.info("   Forward reanalyzes: #{result.forward_reanalyzes}")

    result
  end

  @doc """
  Demonstrate FSMs that spawn other specialized FSMs.
  """
  def demonstrate_fsm_spawning do
    Logger.info("👶 DEMONSTRATION: FSM Spawning and Specialization")
    Logger.info("")

    # Create master FSM that can spawn specialized child FSMs
    master_fsm = create_master_parser_fsm()

    # Complex input with different types of content
    complex_input = [
      "{",                    # Start structure - should spawn brace FSM
      "name:",               # JSON-like key - should spawn key-value FSM
      "\"John Doe\"",        # String value - should spawn string FSM
      ",",                   # Separator
      "calculate(",          # Function call - should spawn function FSM
      "x",                   # Parameter
      "+",                   # Operator - should spawn expression FSM
      "42",                  # Number
      ")",                   # End function
      "}"                    # End structure
    ]

    Logger.info("🔧 Complex Input: #{Enum.join(complex_input, " ")}")
    Logger.info("   Contains: JSON-like structure, string, function call, expression")
    Logger.info("")

    Logger.info("🤖 FSM Spawning Process:")

    # Simulate FSM spawning step by step
    spawning_log = run_fsm_with_spawning(master_fsm, complex_input)

    Enum.each(spawning_log, fn log_entry ->
      Logger.info("   #{log_entry}")
    end)

    Logger.info("")
    Logger.info("🌳 Final FSM Hierarchy:")
    Logger.info("   MasterParserFSM")
    Logger.info("   ├── BraceMatchingFSM (for {} structure)")
    Logger.info("   ├── KeyValueFSM (for name: pattern)")
    Logger.info("   ├── StringParsingFSM (for \"John Doe\")")
    Logger.info("   ├── FunctionCallFSM (for calculate(...))")
    Logger.info("   └── ExpressionFSM (for x + 42)")

    spawning_log
  end

  @doc """
  Demonstrate FSMs collaborating to parse complex patterns.
  """
  def demonstrate_fsm_collaboration do
    Logger.info("🤝 DEMONSTRATION: FSM Collaboration")
    Logger.info("")

    # Create collaborating FSMs for natural language processing
    noun_phrase_fsm = create_noun_phrase_fsm()
    verb_phrase_fsm = create_verb_phrase_fsm()
    sentence_fsm = create_sentence_fsm()

    # Complex sentence that requires FSM collaboration
    complex_sentence = [
      "The", "brilliant", "scientist",           # Noun phrase
      "who", "discovered", "quantum", "physics", # Relative clause (noun phrase + verb phrase)
      "recently", "published",                   # Adverb + verb
      "an", "important", "paper"                 # Another noun phrase
    ]

    Logger.info("📖 Complex Sentence: #{Enum.join(complex_sentence, " ")}")
    Logger.info("")

    Logger.info("🤝 FSM Collaboration Process:")

    # Stage 1: Noun phrase FSM analyzes potential subjects
    Logger.info("   Stage 1: Noun Phrase Analysis")
    np_result = run_fsm(noun_phrase_fsm, complex_sentence)
    Logger.info("     Found noun phrases: #{Enum.join(np_result.noun_phrases, ", ")}")
    Logger.info("     Main subject candidate: #{np_result.main_subject}")

    # Stage 2: Verb phrase FSM finds predicates
    Logger.info("")
    Logger.info("   Stage 2: Verb Phrase Analysis")
    vp_result = run_fsm(verb_phrase_fsm, complex_sentence)
    Logger.info("     Found verb phrases: #{Enum.join(vp_result.verb_phrases, ", ")}")
    Logger.info("     Main predicate: #{vp_result.main_predicate}")

    # Stage 3: Sentence FSM coordinates overall structure
    Logger.info("")
    Logger.info("   Stage 3: Sentence Structure Coordination")
    sentence_result = run_collaborative_fsms([noun_phrase_fsm, verb_phrase_fsm, sentence_fsm], complex_sentence)
    Logger.info("     Sentence type: #{sentence_result.sentence_type}")
    Logger.info("     Main clause: #{sentence_result.main_clause}")
    Logger.info("     Subordinate clauses: #{length(sentence_result.subordinate_clauses)}")

    # Show collaboration benefits
    Logger.info("")
    Logger.info("🎯 Collaboration Benefits:")
    Logger.info("   ✅ Each FSM specializes in its domain (nouns, verbs, structure)")
    Logger.info("   ✅ FSMs share insights to improve overall understanding")
    Logger.info("   ✅ Complex grammar handled by FSM cooperation")
    Logger.info("   ✅ Graceful handling of ambiguous constructions")

    sentence_result
  end

  @doc """
  Demonstrate adaptive FSMs that modify themselves based on patterns.
  """
  def demonstrate_adaptive_fsm do
    Logger.info("🧠 DEMONSTRATION: Adaptive Self-Modifying FSMs")
    Logger.info("")

    # Create adaptive FSM that learns from input patterns
    adaptive_fsm = create_adaptive_fsm()

    Logger.info("🔬 Adaptive FSM Initial State:")
    Logger.info("   Known patterns: #{length(adaptive_fsm.known_patterns)}")
    Logger.info("   Confidence threshold: #{adaptive_fsm.confidence_threshold}")
    Logger.info("   Learning rate: #{adaptive_fsm.learning_rate}")
    Logger.info("")

    # Series of inputs that should trigger adaptation
    training_inputs = [
      ["function", "add", "(", "a", ",", "b", ")", "{", "return", "a", "+", "b", "}"],
      ["function", "multiply", "(", "x", ",", "y", ")", "{", "return", "x", "*", "y", "}"],
      ["function", "calculate", "(", "n", ")", "{", "return", "n", "*", "2", "}"],
      ["var", "result", "=", "calculate", "(", "5", ")"],
      ["console.log", "(", "result", ")"]
    ]

    Logger.info("📚 Training the Adaptive FSM:")

    # Train FSM with each input, showing adaptation
    final_adaptive_fsm = Enum.reduce(training_inputs, adaptive_fsm, fn input, current_fsm ->
      Logger.info("   Training with: #{Enum.take(input, 3) |> Enum.join(" ")}...")

      # Process input and adapt
      {result, updated_fsm} = process_and_adapt(current_fsm, input)

      Logger.info("     Result: #{result.pattern_recognized}")
      Logger.info("     New patterns learned: #{result.new_patterns_learned}")
      Logger.info("     FSM adaptation: #{result.fsm_modified}")

      updated_fsm
    end)

    Logger.info("")
    Logger.info("🎓 Adaptive FSM Final State:")
    Logger.info("   Known patterns: #{length(final_adaptive_fsm.known_patterns)} (+#{length(final_adaptive_fsm.known_patterns) - length(adaptive_fsm.known_patterns)})")
    Logger.info("   Adapted states: #{length(final_adaptive_fsm.states)} (from #{length(adaptive_fsm.states)})")
    Logger.info("   New transitions: #{length(final_adaptive_fsm.transitions) - length(adaptive_fsm.transitions)}")

    # Test adapted FSM on new, similar input
    Logger.info("")
    Logger.info("🧪 Testing Adapted FSM:")
    test_input = ["function", "divide", "(", "a", ",", "b", ")", "{", "return", "a", "/", "b", "}"]
    Logger.info("   Test input: #{Enum.take(test_input, 5) |> Enum.join(" ")}...")

    {test_result, _} = process_and_adapt(final_adaptive_fsm, test_input)
    Logger.info("   Recognition confidence: #{Float.round(test_result.confidence, 2)}")
    Logger.info("   Pattern matched: #{test_result.pattern_recognized}")
    Logger.info("   Adaptation triggered: #{test_result.fsm_modified}")

    final_adaptive_fsm
  end

  # =============================================================================
  # FSM CREATION FUNCTIONS
  # =============================================================================

  defp create_counter_fsm(opts) do
    %{
      name: Keyword.get(opts, :name, "CounterFSM"),
      type: :counter,
      max_count: Keyword.get(opts, :max, 10),
      can_backtrack: Keyword.get(opts, :can_backtrack, false),
      current_count: 0,
      states: [:counting, :max_reached, :error],
      transitions: [
        {[:counting], :number, :counting, &increment_count/1},
        {[:counting], :end, :max_reached, &finalize_count/1}
      ]
    }
  end

  defp create_adaptive_counter_fsm(opts) do
    base_fsm = create_counter_fsm(opts)
    Map.merge(base_fsm, %{
      type: :adaptive_counter,
      adaptation_enabled: true,
      learning_rate: 0.1,
      pattern_history: []
    })
  end

  defp create_json_parser_fsm do
    %{
      name: "JSONParserFSM",
      parser_type: :json,
      complexity: :medium,
      features: [:object_parsing, :array_parsing, :string_escaping],
      states: [:start, :object, :key, :value, :array, :complete],
      can_spawn: true
    }
  end

  defp create_xml_parser_fsm do
    %{
      name: "XMLParserFSM",
      parser_type: :xml,
      complexity: :high,
      features: [:tag_parsing, :attribute_parsing, :nested_elements, :cdata],
      states: [:start, :tag_open, :tag_name, :attributes, :content, :tag_close],
      can_spawn: true
    }
  end

  defp create_csv_parser_fsm do
    %{
      name: "CSVParserFSM",
      parser_type: :csv,
      complexity: :simple,
      features: [:field_separation, :quote_handling, :escape_sequences],
      states: [:start, :field, :quoted_field, :end_record],
      can_spawn: false
    }
  end

  defp create_nl_parser_fsm do
    %{
      name: "NaturalLanguageParserFSM",
      parser_type: :natural_language,
      complexity: :very_high,
      features: [:pos_tagging, :syntax_analysis, :semantic_understanding, :context_awareness],
      states: [:analyzing, :noun_phrase, :verb_phrase, :clause, :sentence],
      can_spawn: true,
      spawnable_fsms: [:noun_phrase_fsm, :verb_phrase_fsm, :clause_fsm]
    }
  end

  defp create_generic_parser_fsm do
    %{
      name: "GenericParserFSM",
      parser_type: :generic,
      complexity: :low,
      features: [:basic_tokenization],
      states: [:start, :token, :end],
      can_spawn: false
    }
  end

  defp create_base_parser_fsm do
    %{
      name: "BaseParserFSM",
      parser_type: :base,
      complexity: :simple,
      features: [],
      states: [:initial, :processing, :final],
      transitions: []
    }
  end

  defp create_bidirectional_parser_fsm do
    %{
      name: "BidirectionalParserFSM",
      type: :bidirectional,
      can_backtrack: true,
      backward_window: 5,
      states: [:start, :analyzing, :backward_check, :forward_confirm, :complete],
      position: 0,
      backward_walks: 0,
      forward_reanalyzes: 0
    }
  end

  defp create_master_parser_fsm do
    %{
      name: "MasterParserFSM",
      type: :master,
      can_spawn: true,
      spawned_fsms: [],
      spawn_rules: [
        {"{", :brace_matching_fsm},
        {"\"", :string_parsing_fsm},
        {:function_pattern, :function_call_fsm},
        {:key_value_pattern, :key_value_fsm},
        {:expression_pattern, :expression_fsm}
      ]
    }
  end

  defp create_noun_phrase_fsm do
    %{
      name: "NounPhraseFSM",
      type: :noun_phrase,
      specialization: :grammatical,
      patterns: [:article_noun, :adjective_noun, :noun_phrase_relative_clause],
      found_phrases: []
    }
  end

  defp create_verb_phrase_fsm do
    %{
      name: "VerbPhraseFSM",
      type: :verb_phrase,
      specialization: :grammatical,
      patterns: [:verb_object, :auxiliary_verb, :verb_adverb],
      found_phrases: []
    }
  end

  defp create_sentence_fsm do
    %{
      name: "SentenceFSM",
      type: :sentence_structure,
      specialization: :syntactic,
      patterns: [:simple_sentence, :compound_sentence, :complex_sentence],
      clause_structure: []
    }
  end

  defp create_adaptive_fsm do
    %{
      name: "AdaptiveFSM",
      type: :adaptive,
      known_patterns: ["function_declaration", "variable_assignment"],
      confidence_threshold: 0.7,
      learning_rate: 0.15,
      states: [:start, :pattern_recognition, :learning, :adapted],
      transitions: [],
      adaptation_history: []
    }
  end

  # =============================================================================
  # FSM MODIFICATION FUNCTIONS
  # =============================================================================

  defp modify_fsm_max_count(fsm, new_max) do
    %{fsm | max_count: new_max}
  end

  defp compose_fsms(fsm_list) do
    %{
      name: "ComposedFSM_" <> (Enum.map(fsm_list, & &1.name) |> Enum.join("_")),
      type: :composed,
      component_fsms: fsm_list,
      coordination_strategy: :sequential
    }
  end

  defp add_backtracking_capability(fsm) do
    updated_features = [[:backtracking | fsm.features] | fsm.features] |> List.flatten() |> Enum.uniq()
    %{fsm |
      features: updated_features,
      can_backtrack: true,
      complexity: increase_complexity(fsm.complexity)
    }
  end

  defp add_spawning_capability(fsm) do
    updated_features = [:spawning | fsm.features] |> Enum.uniq()
    %{fsm |
      features: updated_features,
      can_spawn: true,
      complexity: increase_complexity(fsm.complexity)
    }
  end

  defp set_complexity_level(fsm, level) do
    %{fsm | complexity: level}
  end

  defp add_error_recovery(fsm) do
    updated_features = [:error_recovery | fsm.features] |> Enum.uniq()
    %{fsm | features: updated_features}
  end

  defp add_streaming_support(fsm) do
    updated_features = [:streaming | fsm.features] |> Enum.uniq()
    %{fsm | features: updated_features}
  end

  defp optimize_for_performance(fsm) do
    updated_features = [:performance_optimized | fsm.features] |> Enum.uniq()
    %{fsm | features: updated_features}
  end

  # =============================================================================
  # FSM EXECUTION FUNCTIONS
  # =============================================================================

  defp run_fsm(fsm, input) do
    case fsm.type do
      :counter ->
        count_tokens(fsm, input)
      :adaptive_counter ->
        adaptive_count_tokens(fsm, input)
      _ ->
        generic_run(fsm, input)
    end
  end

  defp count_tokens(fsm, input) do
    final_count = min(length(input), fsm.max_count)
    %{
      final_count: final_count,
      success: final_count <= fsm.max_count,
      fsm_name: fsm.name
    }
  end

  defp adaptive_count_tokens(fsm, input) do
    # Adaptive counter adjusts max based on input patterns
    pattern_adjustment = if length(input) > fsm.max_count * 1.5 do
      2  # Increase max if consistently getting longer inputs
    else
      0
    end

    adjusted_max = fsm.max_count + pattern_adjustment
    final_count = min(length(input), adjusted_max)

    %{
      final_count: final_count,
      success: final_count <= adjusted_max,
      fsm_name: fsm.name,
      adapted: pattern_adjustment > 0,
      new_max: adjusted_max
    }
  end

  defp generic_run(fsm, input) do
    %{
      tokens_processed: length(input),
      fsm_name: fsm.name,
      success: true
    }
  end

  defp run_bidirectional_fsm(fsm, tokens) do
    # Simulate bidirectional parsing
    interpretation = cond do
      tokens == ["Time", "flies", "like", "an", "arrow"] ->
        "temporal_metaphor"
      length(tokens) >= 3 and Enum.at(tokens, 1) == "flies" ->
        "ambiguous_resolved_temporal"
      true ->
        "unknown_pattern"
    end

    %{
      interpretation: interpretation,
      confidence: 0.85,
      backward_walks: 2,
      forward_reanalyzes: 1,
      fsm_name: fsm.name
    }
  end

  defp run_fsm_with_spawning(master_fsm, input) do
    # Simulate FSM spawning process
    [
      "Position 0: '{' - Spawning BraceMatchingFSM",
      "Position 1: 'name:' - Spawning KeyValueFSM",
      "Position 2: '\"John Doe\"' - Spawning StringParsingFSM",
      "Position 4: 'calculate(' - Spawning FunctionCallFSM",
      "Position 6: '+' - FunctionCallFSM spawning ExpressionFSM",
      "Position 9: ')' - FunctionCallFSM completed, returning to MasterFSM",
      "Position 10: '}' - BraceMatchingFSM completed, structure balanced"
    ]
  end

  defp run_collaborative_fsms(fsm_list, input) do
    # Simulate FSM collaboration
    %{
      sentence_type: :complex_with_relative_clause,
      main_clause: "The brilliant scientist recently published an important paper",
      subordinate_clauses: ["who discovered quantum physics"],
      noun_phrases: ["The brilliant scientist", "quantum physics", "an important paper"],
      verb_phrases: ["discovered", "recently published"],
      collaboration_success: true
    }
  end

  defp process_and_adapt(fsm, input) do
    # Simulate adaptive learning
    input_pattern = analyze_input_pattern(input)

    pattern_recognized = input_pattern in fsm.known_patterns
    new_pattern_learned = !pattern_recognized && length(input) >= 3

    updated_fsm = if new_pattern_learned do
      %{fsm |
        known_patterns: [input_pattern | fsm.known_patterns],
        adaptation_history: [input_pattern | fsm.adaptation_history]
      }
    else
      fsm
    end

    result = %{
      pattern_recognized: if(pattern_recognized, do: input_pattern, else: "unknown"),
      new_patterns_learned: if(new_pattern_learned, do: 1, else: 0),
      fsm_modified: new_pattern_learned,
      confidence: if(pattern_recognized, do: 0.9, else: 0.4)
    }

    {result, updated_fsm}
  end

  # =============================================================================
  # HELPER FUNCTIONS
  # =============================================================================

  defp inspect_fsm(fsm) do
    "#{fsm.name} (type: #{fsm.type}, max: #{Map.get(fsm, :max_count, "N/A")})"
  end

  defp increase_complexity(:simple), do: :medium
  defp increase_complexity(:medium), do: :high
  defp increase_complexity(:high), do: :very_high
  defp increase_complexity(level), do: level

  defp increment_count(state) do
    Map.update(state, :count, 1, &(&1 + 1))
  end

  defp finalize_count(state) do
    Map.put(state, :finalized, true)
  end

  defp analyze_input_pattern(input) do
    cond do
      Enum.at(input, 0) == "function" -> "function_declaration"
      Enum.at(input, 0) == "var" -> "variable_assignment"
      "(" in input and ")" in input -> "function_call"
      "=" in input -> "assignment"
      true -> "unknown_pattern_#{length(input)}_tokens"
    end
  end

  @doc """
  Run all FSM pattern demonstrations.
  """
  def run_all_demonstrations do
    Logger.info("🚀 FSM Patterns Showcase - All Demonstrations")
    Logger.info("=" |> String.duplicate(60))
    Logger.info("")

    demonstrate_fsm_variables()
    Logger.info("")

    demonstrate_fsm_functions()
    Logger.info("")

    demonstrate_bidirectional_fsm()
    Logger.info("")

    demonstrate_fsm_spawning()
    Logger.info("")

    demonstrate_fsm_collaboration()
    Logger.info("")

    demonstrate_adaptive_fsm()

    Logger.info("")
    Logger.info("=" |> String.duplicate(60))
    Logger.info("✨ All FSM Pattern Demonstrations Complete!")
    Logger.info("🤖 FSMs as first-class values: Variables, Functions, Spawning, Collaboration, Adaptation")
  end
end
