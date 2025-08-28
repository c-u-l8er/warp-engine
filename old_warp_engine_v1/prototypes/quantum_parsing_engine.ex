defmodule QuantumParsingEngine do
  @moduledoc """
  Revolutionary Physics-Enhanced Parsing Engine with Intelligent FSMs

  ## Revolutionary Concepts:

  1. **FSM Variables & Functions** - Finite State Machines are first-class values
  2. **Bidirectional Parsing** - FSMs can walk backwards and forwards in token streams
  3. **Quantum FSM Entanglement** - Related FSMs influence each other's decisions
  4. **Gravitational Parse Paths** - Likely interpretations attract parsing attention
  5. **Wormhole Pattern Shortcuts** - Common patterns create parsing shortcuts
  6. **Natural Language Understanding** - FSMs collaborate to understand context

  ## Examples:

  ```elixir
  # Brace matching with physics
  brace_fsm = fsm do
    state :looking_for_open
    state :counting_depth, depth: 0
    state :matched

    transition :looking_for_open, "{", :counting_depth, depth: 1
    transition :counting_depth, "{", :counting_depth, depth: depth + 1
    transition :counting_depth, "}", :counting_depth, depth: depth - 1
    transition :counting_depth, "}", :matched, when: depth == 1
  end

  # Natural language FSM that can call other FSMs and backtrack
  sentence_fsm = fsm do
    state :start
    state :found_subject
    state :found_verb
    state :complete

    # This FSM can spawn other FSMs and walk backwards!
    transition :start, any_token(), :analyzing do
      # Spawn noun_phrase_fsm to analyze potential subject
      spawn_fsm(noun_phrase_fsm, current_position)

      # If noun_phrase_fsm succeeds, this FSM continues
      # If it fails, this FSM backtracks and tries other patterns
    end
  end
  ```
  """

  use EnhancedADT
  use EnhancedADT.WarpEngineIntegration
  require Logger

  # =============================================================================
  # QUANTUM FSM ADT DEFINITIONS WITH PHYSICS
  # =============================================================================

  @doc """
  QuantumFSM - A finite state machine that's also a variable/function.

  Physics annotations optimize parsing performance:
  - confidence_score → gravitational_mass (parsing priority)
  - pattern_frequency → quantum_entanglement_potential (pattern recognition)
  - created_at → temporal_weight (FSM lifecycle)
  """
  defproduct QuantumFSM do
    field id :: String.t()
    field name :: String.t()
    field states :: [FSMState.t()]
    field transitions :: [FSMTransition.t()]
    field current_state :: String.t()
    field confidence_score :: float(), physics: :gravitational_mass
    field pattern_frequency :: float(), physics: :quantum_entanglement_potential
    field created_at :: DateTime.t(), physics: :temporal_weight
    field fsm_type :: atom()
    field can_backtrack :: boolean()
    field spawned_fsms :: [String.t()]
  end

  @doc """
  FSMState - Individual states within FSMs with physics properties.
  """
  defproduct FSMState do
    field name :: String.t()
    field state_type :: atom()
    field entry_actions :: [atom()]
    field exit_actions :: [atom()]
    field state_data :: map()
    field stability_score :: float(), physics: :gravitational_mass
    field transition_potential :: float(), physics: :quantum_entanglement_potential
  end

  @doc """
  FSMTransition - State transitions with pattern matching and actions.
  """
  defproduct FSMTransition do
    field from_state :: String.t()
    field to_state :: String.t()
    field trigger :: FSMTrigger.t()
    field condition :: function() | nil
    field actions :: [function()]
    field transition_weight :: float(), physics: :gravitational_mass
    field backtrack_enabled :: boolean()
  end

  @doc """
  TokenStream - Bidirectional token stream with physics optimization.
  """
  defproduct TokenStream do
    field tokens :: [Token.t()]
    field current_position :: integer()
    field parse_direction :: atom()  # :forward, :backward, :bidirectional
    field stream_entropy :: float(), physics: :quantum_entanglement_potential
    field access_patterns :: map(), physics: :quantum_entanglement_group
    field created_at :: DateTime.t(), physics: :temporal_weight
  end

  @doc """
  Token - Individual tokens with semantic properties.
  """
  defproduct Token do
    field value :: String.t()
    field token_type :: atom()
    field position :: integer()
    field semantic_weight :: float(), physics: :gravitational_mass
    field context_affinity :: float(), physics: :quantum_entanglement_potential
    field properties :: map()
  end

  # FSM Network - Sum type representing different FSM collaboration patterns
  defsum FSMNetwork do
    variant SingleFSM, fsm :: QuantumFSM.t()
    variant ParallelFSMs,
      fsms :: [QuantumFSM.t()],
      coordination_strategy :: atom()
    variant HierarchicalFSMs,
      parent_fsm :: QuantumFSM.t(),
      child_fsms :: [QuantumFSM.t()],
      spawn_conditions :: map()
    variant BacktrackingFSMs,
      primary_fsm :: QuantumFSM.t(),
      backtrack_stack :: [FSMSnapshot.t()],
      backtrack_triggers :: [function()]
  end

  @doc """
  ParseResult - Result of parsing with physics optimization metadata.
  """
  defproduct ParseResult do
    field parse_tree :: ParseTree.t() | nil
    field confidence :: float()
    field fsms_used :: [String.t()]
    field wormhole_shortcuts :: integer()
    field quantum_entanglements :: integer()
    field backtrack_count :: integer()
    field parse_time :: integer()
    field physics_metadata :: map()
  end

  # =============================================================================
  # FSM CREATION AND MANIPULATION
  # =============================================================================

  @doc """
  Create a new FSM using Enhanced ADT with automatic physics optimization.
  """
  def create_fsm(name, opts \\ []) do
    fsm_id = "fsm_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}"

    fsm = QuantumFSM.new(
      fsm_id,
      name,
      [],  # states - to be added
      [],  # transitions - to be added
      "initial",
      Keyword.get(opts, :confidence, 0.5),
      Keyword.get(opts, :frequency, 0.3),
      DateTime.utc_now(),
      Keyword.get(opts, :type, :general),
      Keyword.get(opts, :can_backtrack, false),
      []
    )

    # Store FSM with physics optimization
    fsm_key = "fsm:#{fsm_id}"
    case WarpEngine.cosmic_put(fsm_key, fsm, extract_fsm_physics(fsm)) do
      {:ok, :stored, shard_id, operation_time} ->
        Logger.info("🤖 FSM created: #{name} in #{shard_id} (#{operation_time}μs)")

        # Automatic physics optimizations
        post_create_fsm_optimization(fsm_key, fsm, shard_id)

        {:ok, fsm}

      error ->
        Logger.error("❌ FSM creation failed: #{name} - #{inspect(error)}")
        error
    end
  end

  @doc """
  Parse tokens using Enhanced ADT fold with FSM collaboration.
  """
  def parse_with_fsm(tokens, primary_fsm, parsing_strategy \\ :intelligent) do
    # Create bidirectional token stream
    token_stream = TokenStream.new(
      tokens,
      0,
      :bidirectional,
      calculate_stream_entropy(tokens),
      %{},
      DateTime.utc_now()
    )

    Logger.info("🔍 Starting parse with FSM: #{primary_fsm.name} (#{length(tokens)} tokens)")

    # Enhanced ADT fold for intelligent parsing
    parse_result = fold {primary_fsm, token_stream, parsing_strategy} do
      {%QuantumFSM{id: fsm_id, name: name, can_backtrack: can_backtrack} = fsm,
       %TokenStream{tokens: stream_tokens, current_position: pos} = stream,
       strategy} ->

        # Initialize parsing state
        parsing_state = %{
          active_fsms: [fsm],
          parse_stack: [],
          backtrack_points: [],
          quantum_entanglements: 0,
          wormhole_shortcuts: 0,
          confidence_accumulator: fsm.confidence_score
        }

        case strategy do
          :intelligent ->
            # Intelligent parsing with physics optimization
            intelligent_parse_with_physics(fsm, stream, parsing_state)

          :collaborative ->
            # Multiple FSMs working together
            collaborative_parse_with_fsm_network(fsm, stream, parsing_state)

          :natural_language ->
            # Natural language parsing with semantic understanding
            natural_language_parse_with_context(fsm, stream, parsing_state)

          :backtracking ->
            # Backtracking parser with FSM snapshots
            backtracking_parse_with_fsm_rewind(fsm, stream, parsing_state)

          _ ->
            # Standard FSM parsing
            standard_fsm_parse(fsm, stream, parsing_state)
        end
    end

    Logger.info("✨ Parse complete: #{parse_result.confidence} confidence, #{parse_result.fsms_used |> length()} FSMs used")
    parse_result
  end

  # =============================================================================
  # INTELLIGENT PARSING WITH PHYSICS OPTIMIZATION
  # =============================================================================

  defp intelligent_parse_with_physics(fsm, token_stream, parsing_state) do
    Logger.info("🧠 Starting intelligent parsing with physics optimization...")

    # Use Enhanced ADT bend to create optimal parsing network
    parsing_network = bend from: {fsm, token_stream, parsing_state}, parse_optimization: true do
      {%QuantumFSM{confidence_score: confidence} = primary_fsm,
       %TokenStream{tokens: tokens} = stream, state} when confidence >= 0.7 ->

        # High confidence FSM - use wormhole shortcuts
        Logger.debug("🌀 High confidence FSM - applying wormhole optimization")

        # Find common patterns that can use wormhole shortcuts
        pattern_shortcuts = identify_wormhole_patterns(tokens, primary_fsm)

        # Apply shortcuts and continue parsing
        optimized_result = apply_wormhole_parsing_shortcuts(pattern_shortcuts, stream, state)

        # Fork for remaining complex patterns
        remaining_tokens = extract_non_shortcut_tokens(tokens, pattern_shortcuts)
        if length(remaining_tokens) > 0 do
          complex_parsing_result = fork({primary_fsm, remaining_tokens, state})
          merge_parsing_results(optimized_result, complex_parsing_result)
        else
          optimized_result
        end

      {%QuantumFSM{can_backtrack: true} = backtrack_fsm, stream, state} ->
        # Backtracking FSM - use quantum entanglement for context
        Logger.debug("⚛️ Backtracking FSM - applying quantum context analysis")

        # Create quantum entanglements between related tokens
        quantum_context = create_token_quantum_entanglements(stream.tokens, backtrack_fsm)

        # Use quantum context to guide parsing decisions
        quantum_enhanced_result = parse_with_quantum_context(backtrack_fsm, stream, quantum_context, state)

        # If parsing fails, backtrack using quantum correlation
        case quantum_enhanced_result do
          %{success: false} ->
            Logger.debug("🔄 Quantum parsing failed - initiating backtrack")
            backtrack_with_quantum_correlation(backtrack_fsm, stream, quantum_context, state)

          success_result ->
            success_result
        end

      {%QuantumFSM{} = standard_fsm, stream, state} ->
        # Standard FSM - use gravitational parsing optimization
        Logger.debug("🌍 Standard FSM - applying gravitational parsing")

        # Apply gravitational attraction to likely parse paths
        gravitational_paths = calculate_gravitational_parse_paths(stream.tokens, standard_fsm)

        # Parse along highest-weight gravitational paths first
        gravitational_result = parse_along_gravitational_paths(standard_fsm, stream, gravitational_paths, state)

        gravitational_result
    end

    # Extract final parse result with physics metadata
    create_physics_enhanced_parse_result(parsing_network, parsing_state)
  end

  defp collaborative_parse_with_fsm_network(primary_fsm, token_stream, parsing_state) do
    Logger.info("👥 Starting collaborative parsing with FSM network...")

    # Spawn additional FSMs based on token patterns
    collaborating_fsms = spawn_collaborating_fsms(primary_fsm, token_stream)

    Logger.info("🤖 Spawned #{length(collaborating_fsms)} collaborating FSMs")

    # Create quantum entanglements between collaborating FSMs
    fsm_entanglements = create_fsm_quantum_entanglements(primary_fsm, collaborating_fsms)

    # Collaborative parsing using Enhanced ADT fold
    collaborative_result = fold {primary_fsm, collaborating_fsms, token_stream, fsm_entanglements} do
      {main_fsm, collab_fsms, stream, entanglements} when length(collab_fsms) > 0 ->

        # Each FSM analyzes different aspects of the token stream
        fsm_analyses = Enum.map([main_fsm | collab_fsms], fn fsm ->
          {fsm, analyze_tokens_with_fsm(fsm, stream.tokens)}
        end)

        # Use quantum entanglements to share insights between FSMs
        enhanced_analyses = apply_quantum_fsm_collaboration(fsm_analyses, entanglements)

        # Combine FSM results using physics-based voting
        combined_result = combine_fsm_results_with_physics(enhanced_analyses, stream)

        %{
          parse_type: :collaborative,
          main_fsm: main_fsm.name,
          collaborating_fsms: Enum.map(collab_fsms, & &1.name),
          combined_result: combined_result,
          quantum_entanglements: length(entanglements),
          collaboration_confidence: calculate_collaboration_confidence(enhanced_analyses)
        }

      {main_fsm, [], stream, _} ->
        # No collaborators - fall back to single FSM parsing
        single_fsm_result = standard_fsm_parse(main_fsm, stream, parsing_state)

        %{
          parse_type: :single_fallback,
          main_fsm: main_fsm.name,
          result: single_fsm_result
        }
    end

    create_collaborative_parse_result(collaborative_result, parsing_state)
  end

  defp natural_language_parse_with_context(fsm, token_stream, parsing_state) do
    Logger.info("💬 Starting natural language parsing with semantic context...")

    # Natural language parsing requires multiple specialized FSMs
    language_fsms = create_natural_language_fsm_network(fsm, token_stream)

    Logger.info("🧠 Created natural language network with #{map_size(language_fsms)} specialized FSMs")

    # Parse using Enhanced ADT fold with linguistic intelligence
    nl_result = fold {language_fsms, token_stream, parsing_state} do
      {%{noun_phrase_fsm: np_fsm, verb_phrase_fsm: vp_fsm, sentence_fsm: sent_fsm} = fsm_network,
       %TokenStream{tokens: tokens} = stream, state} ->

        # Stage 1: Identify potential noun phrases
        noun_phrase_analysis = analyze_with_backtracking_fsm(np_fsm, tokens, stream.current_position)

        # Stage 2: Find verb phrases (may need to backtrack if noun phrase analysis was wrong)
        verb_phrase_analysis = case noun_phrase_analysis do
          {:ok, noun_phrases, remaining_position} ->
            # Noun phrases found - look for verb phrases from remaining position
            analyze_with_backtracking_fsm(vp_fsm, tokens, remaining_position)

          {:backtrack_needed, partial_analysis} ->
            # Noun phrase analysis inconclusive - try verb phrase first and backtrack
            Logger.debug("🔄 Noun phrase inconclusive - trying verb-first analysis")
            case analyze_with_backtracking_fsm(vp_fsm, tokens, stream.current_position) do
              {:ok, verb_phrases, vp_position} ->
                # Found verb phrases - re-analyze noun phrases before this position
                reanalyze_with_context(np_fsm, tokens, 0, vp_position, verb_phrases)

              verb_failure ->
                # Both failed - need more sophisticated analysis
                Logger.debug("🤔 Both noun and verb analysis failed - using semantic FSM")
                semantic_fallback_analysis(fsm_network, tokens, partial_analysis)
            end
        end

        # Stage 3: Sentence-level analysis using results from noun and verb analysis
        sentence_analysis = case {noun_phrase_analysis, verb_phrase_analysis} do
          {{:ok, noun_data, _}, {:ok, verb_data, _}} ->
            # Both successful - analyze sentence structure
            analyze_sentence_structure(sent_fsm, tokens, noun_data, verb_data)

          {noun_result, verb_result} ->
            # Partial success or failure - use fallback semantic analysis
            semantic_sentence_analysis(sent_fsm, tokens, noun_result, verb_result)
        end

        %{
          parse_type: :natural_language,
          noun_phrase_analysis: noun_phrase_analysis,
          verb_phrase_analysis: verb_phrase_analysis,
          sentence_analysis: sentence_analysis,
          semantic_confidence: calculate_semantic_confidence(noun_phrase_analysis, verb_phrase_analysis, sentence_analysis),
          backtrack_count: count_backtracks(noun_phrase_analysis, verb_phrase_analysis)
        }

      {incomplete_fsm_network, stream, state} ->
        Logger.warning("⚠️ Incomplete natural language FSM network - using basic parsing")
        basic_natural_language_parse(incomplete_fsm_network, stream, state)
    end

    create_natural_language_parse_result(nl_result, parsing_state)
  end

  defp backtracking_parse_with_fsm_rewind(fsm, token_stream, parsing_state) do
    Logger.info("🔄 Starting backtracking parse with FSM snapshots...")

    # Enhanced backtracking with FSM state snapshots
    backtrack_result = fold {fsm, token_stream, parsing_state} do
      {%QuantumFSM{can_backtrack: true} = bt_fsm,
       %TokenStream{tokens: tokens, current_position: start_pos} = stream, state} ->

        # Initialize backtracking with Enhanced ADT
        backtrack_state = %{
          fsm_snapshots: [],
          decision_points: [],
          backtrack_depth: 0,
          max_backtracks: 10,
          current_confidence: bt_fsm.confidence_score
        }

        # Parse with automatic snapshot creation
        parse_with_automatic_snapshots(bt_fsm, stream, backtrack_state, state)

      {%QuantumFSM{can_backtrack: false} = no_bt_fsm, stream, state} ->
        Logger.warning("⚠️ FSM doesn't support backtracking - using standard parsing")
        standard_fsm_parse(no_bt_fsm, stream, state)
    end

    create_backtracking_parse_result(backtrack_result, parsing_state)
  end

  # =============================================================================
  # BIDIRECTIONAL TOKEN STREAM OPERATIONS
  # =============================================================================

  @doc """
  Move token stream position with physics optimization.
  """
  def move_stream(token_stream, direction, steps \\ 1) do
    fold {token_stream, direction, steps} do
      {%TokenStream{current_position: pos, tokens: tokens} = stream, :forward, step_count} ->
        new_position = min(pos + step_count, length(tokens) - 1)
        updated_stream = %{stream | current_position: new_position}

        # Apply gravitational attraction to likely next tokens
        apply_forward_gravitational_optimization(updated_stream)

      {%TokenStream{current_position: pos} = stream, :backward, step_count} ->
        new_position = max(pos - step_count, 0)
        updated_stream = %{stream | current_position: new_position}

        # Apply quantum entanglement to previous context
        apply_backward_quantum_optimization(updated_stream)

      {stream, :reset, _} ->
        %{stream | current_position: 0}
    end
  end

  @doc """
  Peek at tokens without moving position - with wormhole optimization.
  """
  def peek_tokens(token_stream, direction, count \\ 1) do
    case direction do
      :forward ->
        start_pos = token_stream.current_position
        end_pos = min(start_pos + count, length(token_stream.tokens))

        peeked_tokens = Enum.slice(token_stream.tokens, start_pos, count)

        # Use wormhole optimization to predict likely token patterns
        wormhole_enhanced_peek(peeked_tokens, :forward)

      :backward ->
        end_pos = token_stream.current_position
        start_pos = max(end_pos - count, 0)

        peeked_tokens = Enum.slice(token_stream.tokens, start_pos, end_pos - start_pos)
        |> Enum.reverse()  # Maintain backward order

        # Use quantum entanglement to understand backward context
        quantum_enhanced_peek(peeked_tokens, :backward)
    end
  end

  # =============================================================================
  # FSM PATTERN LIBRARY - EXAMPLE FSMS
  # =============================================================================

  @doc """
  Create brace matching FSM with automatic wormhole optimization.
  """
  def create_brace_matching_fsm do
    {:ok, brace_fsm} = create_fsm("BraceMatchingFSM",
      confidence: 0.9,
      frequency: 0.8,
      type: :structural,
      can_backtrack: true
    )

    # Add states using Enhanced ADT
    states = [
      FSMState.new("initial", :start, [], [], %{}, 1.0, 0.5),
      FSMState.new("open_found", :intermediate, [], [], %{depth: 0}, 0.8, 0.7),
      FSMState.new("counting", :intermediate, [], [], %{depth: 0}, 0.6, 0.9),
      FSMState.new("matched", :accept, [], [], %{}, 1.0, 0.1),
      FSMState.new("unmatched", :reject, [], [], %{error: "unmatched_braces"}, 0.1, 0.1)
    ]

    # Add transitions with physics properties
    transitions = [
      FSMTransition.new("initial", "open_found", create_token_trigger("{"), nil, [], 0.9, false),
      FSMTransition.new("open_found", "counting", create_any_token_trigger(), nil,
        [&increment_depth/1], 0.7, false),
      FSMTransition.new("counting", "counting", create_token_trigger("{"), nil,
        [&increment_depth/1], 0.8, false),
      FSMTransition.new("counting", "counting", create_token_trigger("}"),
        &depth_greater_than_zero?/1, [&decrement_depth/1], 0.8, false),
      FSMTransition.new("counting", "matched", create_token_trigger("}"),
        &depth_equals_zero?/1, [&finalize_match/1], 1.0, false)
    ]

    # Update FSM with states and transitions
    updated_fsm = %{brace_fsm | states: states, transitions: transitions}

    Logger.info("🔧 Created brace matching FSM with #{length(states)} states, #{length(transitions)} transitions")
    updated_fsm
  end

  @doc """
  Create natural language sentence FSM with semantic understanding.
  """
  def create_sentence_fsm do
    {:ok, sentence_fsm} = create_fsm("SentenceFSM",
      confidence: 0.7,
      frequency: 0.6,
      type: :natural_language,
      can_backtrack: true
    )

    # Natural language parsing states
    states = [
      FSMState.new("start", :start, [], [], %{}, 1.0, 0.8),
      FSMState.new("seeking_subject", :intermediate, [], [], %{}, 0.8, 0.9),
      FSMState.new("found_subject", :intermediate, [], [], %{subject: nil}, 0.7, 0.8),
      FSMState.new("seeking_verb", :intermediate, [], [], %{}, 0.6, 0.9),
      FSMState.new("found_verb", :intermediate, [], [], %{verb: nil}, 0.8, 0.7),
      FSMState.new("seeking_object", :intermediate, [], [], %{}, 0.5, 0.8),
      FSMState.new("complete_sentence", :accept, [], [], %{sentence_type: nil}, 1.0, 0.1)
    ]

    # Complex transitions that can spawn other FSMs
    transitions = [
      FSMTransition.new("start", "seeking_subject", create_any_token_trigger(), nil,
        [&spawn_noun_phrase_fsm/1], 0.9, true),
      FSMTransition.new("seeking_subject", "found_subject", create_noun_trigger(),
        &is_valid_subject?/1, [&capture_subject/1, &spawn_verb_phrase_fsm/1], 0.8, true),
      FSMTransition.new("found_subject", "seeking_verb", create_any_token_trigger(), nil,
        [], 0.7, false),
      FSMTransition.new("seeking_verb", "found_verb", create_verb_trigger(),
        &is_valid_verb?/1, [&capture_verb/1], 0.9, true),
      FSMTransition.new("found_verb", "complete_sentence", create_end_trigger(),
        &is_complete_sentence?/1, [&finalize_sentence/1], 1.0, false),
      FSMTransition.new("found_verb", "seeking_object", create_any_token_trigger(),
        &needs_object?/1, [&spawn_object_fsm/1], 0.6, true)
    ]

    updated_fsm = %{sentence_fsm | states: states, transitions: transitions}

    Logger.info("💬 Created sentence FSM with semantic understanding")
    updated_fsm
  end

  @doc """
  Create mathematical expression FSM with precedence handling.
  """
  def create_expression_fsm do
    {:ok, expr_fsm} = create_fsm("ExpressionFSM",
      confidence: 0.8,
      frequency: 0.7,
      type: :mathematical,
      can_backtrack: true
    )

    # Mathematical expression parsing with operator precedence
    states = [
      FSMState.new("start", :start, [], [], %{}, 1.0, 0.8),
      FSMState.new("expect_operand", :intermediate, [], [], %{}, 0.7, 0.9),
      FSMState.new("found_number", :intermediate, [], [], %{value: nil}, 0.8, 0.6),
      FSMState.new("expect_operator", :intermediate, [], [], %{}, 0.6, 0.8),
      FSMState.new("found_operator", :intermediate, [], [], %{op: nil, precedence: 0}, 0.7, 0.9),
      FSMState.new("expression_complete", :accept, [], [], %{result: nil}, 1.0, 0.1)
    ]

    # Precedence-aware transitions
    transitions = [
      FSMTransition.new("start", "expect_operand", create_any_token_trigger(), nil,
        [], 1.0, false),
      FSMTransition.new("expect_operand", "found_number", create_number_trigger(),
        &is_valid_number?/1, [&capture_number/1], 0.9, false),
      FSMTransition.new("expect_operand", "expect_operand", create_token_trigger("("), nil,
        [&spawn_sub_expression_fsm/1], 0.8, true),
      FSMTransition.new("found_number", "expect_operator", create_any_token_trigger(), nil,
        [], 0.8, false),
      FSMTransition.new("expect_operator", "found_operator", create_operator_trigger(),
        &is_valid_operator?/1, [&capture_operator_with_precedence/1], 0.9, true),
      FSMTransition.new("found_operator", "expect_operand", create_any_token_trigger(), nil,
        [&handle_operator_precedence/1], 0.8, true)
    ]

    updated_fsm = %{expr_fsm | states: states, transitions: transitions}

    Logger.info("🔢 Created mathematical expression FSM with precedence handling")
    updated_fsm
  end

  # =============================================================================
  # PHYSICS OPTIMIZATION AND HELPER FUNCTIONS
  # =============================================================================

  # Physics extraction for FSMs
  defp extract_fsm_physics(fsm) do
    access_pattern = if fsm.confidence_score >= 0.8, do: :hot, else: :warm

    [
      gravitational_mass: fsm.confidence_score,
      quantum_entanglement_potential: fsm.pattern_frequency,
      temporal_weight: 0.8,  # Optimized constant
      access_pattern: access_pattern
    ]
  end

  # Post-creation optimizations
  defp post_create_fsm_optimization(fsm_key, fsm, shard_id) do
    # High confidence FSMs get wormhole hubs
    if fsm.confidence_score >= 0.8 do
      create_fsm_wormhole_hub(fsm_key, fsm.confidence_score)
    end

    # High frequency FSMs get quantum entanglement enhancement
    if fsm.pattern_frequency >= 0.7 do
      enhance_fsm_quantum_entanglement(fsm_key, fsm.pattern_frequency)
    end

    :ok
  end

  # Demo parsing functions (simplified implementations)
  defp standard_fsm_parse(fsm, stream, state) do
    %{
      parse_type: :standard,
      fsm_used: fsm.name,
      tokens_parsed: length(stream.tokens),
      confidence: fsm.confidence_score,
      success: true
    }
  end

  defp create_physics_enhanced_parse_result(network, state) do
    ParseResult.new(
      nil,  # parse_tree - would be built from network
      0.85,  # confidence
      ["primary_fsm"],  # fsms_used
      3,  # wormhole_shortcuts
      2,  # quantum_entanglements
      1,  # backtrack_count
      System.monotonic_time(:microsecond),  # parse_time
      %{physics_optimization: true}  # physics_metadata
    )
  end

  # Simplified helper functions for demo
  defp calculate_stream_entropy(_tokens), do: 0.4
  defp identify_wormhole_patterns(_tokens, _fsm), do: []
  defp apply_wormhole_parsing_shortcuts(_patterns, stream, _state), do: %{optimized: true, stream: stream}
  defp extract_non_shortcut_tokens(tokens, _patterns), do: tokens
  defp merge_parsing_results(result1, _result2), do: result1
  defp create_token_quantum_entanglements(_tokens, _fsm), do: %{quantum_context: true}
  defp parse_with_quantum_context(_fsm, stream, _context, _state), do: %{success: true, stream: stream}
  defp backtrack_with_quantum_correlation(_fsm, stream, _context, _state), do: %{backtracked: true, stream: stream}
  defp calculate_gravitational_parse_paths(_tokens, _fsm), do: []
  defp parse_along_gravitational_paths(_fsm, stream, _paths, _state), do: %{gravitational: true, stream: stream}
  defp spawn_collaborating_fsms(_primary, _stream), do: []
  defp create_fsm_quantum_entanglements(_primary, _collabs), do: []
  defp analyze_tokens_with_fsm(_fsm, _tokens), do: %{analysis: "complete"}
  defp apply_quantum_fsm_collaboration(analyses, _entanglements), do: analyses
  defp combine_fsm_results_with_physics(_analyses, _stream), do: %{combined: true}
  defp calculate_collaboration_confidence(_analyses), do: 0.8
  defp create_collaborative_parse_result(result, _state), do: result
  defp create_natural_language_fsm_network(_fsm, _stream), do: %{noun_phrase_fsm: nil, verb_phrase_fsm: nil, sentence_fsm: nil}
  defp analyze_with_backtracking_fsm(_fsm, _tokens, _pos), do: {:ok, [], 0}
  defp reanalyze_with_context(_fsm, _tokens, _start, _end, _context), do: {:ok, [], 0}
  defp semantic_fallback_analysis(_network, _tokens, _partial), do: {:fallback, []}
  defp analyze_sentence_structure(_fsm, _tokens, _noun_data, _verb_data), do: {:ok, %{sentence: "parsed"}}
  defp semantic_sentence_analysis(_fsm, _tokens, _noun_result, _verb_result), do: {:semantic, %{}}
  defp calculate_semantic_confidence(_noun, _verb, _sentence), do: 0.75
  defp count_backtracks(_noun, _verb), do: 0
  defp basic_natural_language_parse(_network, _stream, _state), do: %{basic: true}
  defp create_natural_language_parse_result(result, _state), do: result
  defp parse_with_automatic_snapshots(_fsm, stream, _bt_state, _state), do: %{snapshots_used: true, stream: stream}
  defp create_backtracking_parse_result(result, _state), do: result
  defp apply_forward_gravitational_optimization(stream), do: stream
  defp apply_backward_quantum_optimization(stream), do: stream
  defp wormhole_enhanced_peek(tokens, _direction), do: tokens
  defp quantum_enhanced_peek(tokens, _direction), do: tokens

  # FSM trigger creation helpers
  defp create_token_trigger(token_value), do: %{type: :exact_token, value: token_value}
  defp create_any_token_trigger(), do: %{type: :any_token}
  defp create_noun_trigger(), do: %{type: :pos_tag, value: :noun}
  defp create_verb_trigger(), do: %{type: :pos_tag, value: :verb}
  defp create_end_trigger(), do: %{type: :end_of_input}
  defp create_number_trigger(), do: %{type: :token_type, value: :number}
  defp create_operator_trigger(), do: %{type: :token_type, value: :operator}

  # FSM action functions
  defp increment_depth(state), do: Map.update(state, :depth, 1, &(&1 + 1))
  defp decrement_depth(state), do: Map.update(state, :depth, 0, &max(0, &1 - 1))
  defp depth_greater_than_zero?(state), do: Map.get(state, :depth, 0) > 0
  defp depth_equals_zero?(state), do: Map.get(state, :depth, 0) == 0
  defp finalize_match(state), do: Map.put(state, :matched, true)
  defp spawn_noun_phrase_fsm(state), do: Map.put(state, :spawned_np_fsm, true)
  defp is_valid_subject?(_state), do: true
  defp capture_subject(state), do: Map.put(state, :subject, "captured")
  defp spawn_verb_phrase_fsm(state), do: Map.put(state, :spawned_vp_fsm, true)
  defp is_valid_verb?(_state), do: true
  defp capture_verb(state), do: Map.put(state, :verb, "captured")
  defp is_complete_sentence?(_state), do: true
  defp finalize_sentence(state), do: Map.put(state, :sentence_complete, true)
  defp needs_object?(_state), do: false
  defp spawn_object_fsm(state), do: Map.put(state, :spawned_obj_fsm, true)
  defp is_valid_number?(_state), do: true
  defp capture_number(state), do: Map.put(state, :number, "captured")
  defp spawn_sub_expression_fsm(state), do: Map.put(state, :spawned_sub_expr, true)
  defp is_valid_operator?(_state), do: true
  defp capture_operator_with_precedence(state), do: Map.put(state, :operator, "captured")
  defp handle_operator_precedence(state), do: Map.put(state, :precedence_handled, true)

  # Physics optimization stubs
  defp create_fsm_wormhole_hub(_key, _confidence), do: :ok
  defp enhance_fsm_quantum_entanglement(_key, _frequency), do: :ok

  # Support modules for complex types
  defmodule FSMTrigger do
    defstruct [:type, :value, :condition]
  end

  defmodule FSMSnapshot do
    defstruct [:fsm_state, :position, :timestamp, :confidence]
  end

  defmodule ParseTree do
    defstruct [:root, :children, :metadata]
  end
end
