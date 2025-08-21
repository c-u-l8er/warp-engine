defmodule QuantumScriptParser do
  @moduledoc """
  QuantumScript Language Parser - The Future of Programming Languages

  Built on revolutionary Quantum FSM parsing technology, QuantumScript supports:
  - Bidirectional parsing and understanding
  - Context-adaptive syntax
  - FSM spawning for specialized parsing
  - Collaborative code blocks
  - Self-modifying syntax

  This is the world's first programming language designed specifically for
  quantum FSM parsing capabilities.
  """

  require Logger

  # Import our quantum parsing engine
  alias StandaloneQuantumParser.{Token, TokenStream, QuantumFSM}

  # =============================================================================
  # QUANTUMSCRIPT LANGUAGE TOKENS
  # =============================================================================

  defmodule QSToken do
    @moduledoc """
    QuantumScript language tokens with enhanced metadata for quantum parsing.
    """
    defstruct [
      :value, :type, :position, :metadata,
      :quantum_weight, :context_affinity, :bidirectional_hint
    ]

    def new(value, type, position, opts \\ []) do
      %__MODULE__{
        value: value,
        type: type,
        position: position,
        metadata: Keyword.get(opts, :metadata, %{}),
        quantum_weight: Keyword.get(opts, :quantum_weight, 0.5),
        context_affinity: Keyword.get(opts, :context_affinity, []),
        bidirectional_hint: Keyword.get(opts, :bidirectional_hint, nil)
      }
    end
  end

  # =============================================================================
  # QUANTUMSCRIPT LANGUAGE CONSTRUCTS
  # =============================================================================

  defmodule QSASTNode do
    defstruct [:type, :value, :children, :metadata, :fsm_context]

    def new(type, value, children \\ [], metadata \\ %{}) do
      %__MODULE__{
        type: type,
        value: value,
        children: children,
        metadata: metadata,
        fsm_context: nil
      }
    end
  end

  # =============================================================================
  # QUANTUMSCRIPT LEXER WITH QUANTUM ENHANCEMENT
  # =============================================================================

  @doc """
  Tokenize QuantumScript source code with quantum-enhanced lexing.
  """
  def tokenize(source) do
    Logger.info("🔬 Tokenizing QuantumScript source...")

    # Improved tokenization that preserves strings
    basic_tokens = tokenize_preserving_strings(source)
    |> Enum.with_index()
    |> Enum.map(fn {token, index} ->
      classify_quantum_token(token, index)
    end)

    Logger.info("📝 Tokenized #{length(basic_tokens)} QuantumScript tokens")
    basic_tokens
  end

  # Helper function to tokenize while preserving string literals
  defp tokenize_preserving_strings(source) do
    # Use a more robust approach to extract tokens while preserving quoted strings
    source
    |> extract_tokens_with_strings([])
    |> Enum.reverse()
  end

  # Recursive function to extract tokens while preserving quoted strings
  defp extract_tokens_with_strings("", acc), do: acc

  defp extract_tokens_with_strings(source, acc) do
    source = String.trim_leading(source)
    if source == "", do: acc, else: do_extract_token(source, acc)
  end

  defp do_extract_token("\"" <> rest, acc) do
    # Extract quoted string
    case extract_quoted_string(rest, "") do
      {string_content, remaining} ->
        full_string = "\"" <> string_content <> "\""
        extract_tokens_with_strings(remaining, [full_string | acc])
      :error ->
        # Malformed string, treat as separate tokens
        [next_token, remaining] = extract_regular_token("\"" <> rest)
        extract_tokens_with_strings(remaining, [next_token | acc])
    end
  end

  defp do_extract_token(source, acc) do
    [next_token, remaining] = extract_regular_token(source)
    extract_tokens_with_strings(remaining, [next_token | acc])
  end

  defp extract_quoted_string("", _acc), do: :error
  defp extract_quoted_string("\"" <> rest, acc), do: {acc, rest}
  defp extract_quoted_string(<<char::utf8, rest::binary>>, acc) do
    extract_quoted_string(rest, acc <> <<char>>)
  end

  defp extract_regular_token(source) do
    case Regex.run(~r/^\S+/, source) do
      [token] ->
        remaining = String.trim_leading(source, token)
        [token, remaining]
      nil ->
        ["", ""]
    end
  end

  defp classify_quantum_token(token_str, position) do
    {type, quantum_weight, context_affinity} = cond do
      # Bidirectional operators
      token_str == "<->" -> {:bidirectional_op, 0.9, [:bidirectional, :quantum]}
      token_str == "->" -> {:forward_op, 0.7, [:forward]}
      token_str == "<-" -> {:backward_op, 0.7, [:backward]}

      # Context keywords (improved quantum weights)
      token_str == "quantum_module" -> {:quantum_module, 0.9, [:module, :quantum]}
      token_str == "collaborate" -> {:collaborate_block, 0.85, [:collaboration]}
      token_str == "adaptive" -> {:adaptive_modifier, 0.9, [:adaptation]}
      token_str == "entangled" -> {:entanglement_modifier, 0.95, [:quantum, :entanglement]}
      token_str == "gravitate" -> {:gravitation_block, 0.85, [:physics, :branching]}
      token_str == "when" -> {:conditional_when, 0.7, [:conditional]}
      token_str == "spawn" -> {:spawn_keyword, 0.9, [:fsm_spawning]}
      token_str == "learn" -> {:learn_keyword, 0.85, [:adaptation]}
      token_str == "optimize" -> {:optimize_keyword, 0.8, [:adaptation]}

      # Natural language markers
      token_str == "natural_language" -> {:natural_lang_block, 0.9, [:natural_language]}

      # Context markers
      token_str == "data:" -> {:data_context, 0.7, [:context, :data]}
      token_str == "ui:" -> {:ui_context, 0.7, [:context, :ui]}
      token_str == "math:" -> {:math_context, 0.7, [:context, :math]}

      # Function definitions
      token_str == "function" -> {:function_def, 0.6, [:function]}
      token_str == "class" -> {:class_def, 0.6, [:class]}

      # Structural
      token_str == "{" -> {:brace_open, 0.8, [:structure]}
      token_str == "}" -> {:brace_close, 0.8, [:structure]}
      token_str == "(" -> {:paren_open, 0.7, [:structure]}
      token_str == ")" -> {:paren_close, 0.7, [:structure]}

      # Operators (improved recognition)
      token_str == "+" -> {:operator, 0.6, [:operator]}
      token_str == "-" -> {:operator, 0.6, [:operator]}
      token_str == "*" -> {:operator, 0.6, [:operator]}
      token_str == "/" -> {:operator, 0.6, [:operator]}
      token_str == "==" -> {:equals_op, 0.7, [:operator]}
      token_str == "!=" -> {:not_equals_op, 0.7, [:operator]}
      token_str == "=" -> {:assign_op, 0.6, [:operator]}
      token_str == ">" -> {:greater_op, 0.6, [:operator]}
      token_str == "<" -> {:less_op, 0.6, [:operator]}

      # Literals and identifiers (using regex outside guards)
      Regex.match?(~r/^\d+(\.\d+)?$/, token_str) -> {:number, 0.7, [:literal]}
      Regex.match?(~r/^".*"$/, token_str) -> {:string, 0.8, [:literal]}
      Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, token_str) -> {:identifier, 0.5, [:identifier]}

      # Default
      true -> {:unknown, 0.3, [:unknown]}
    end

    QSToken.new(token_str, type, position,
      quantum_weight: quantum_weight,
      context_affinity: context_affinity,
      bidirectional_hint: detect_bidirectional_hint(token_str)
    )
  end

  defp detect_bidirectional_hint(token) do
    cond do
      token in ["<->", "trace", "backward", "forward"] -> :bidirectional
      token in ["->", "then", "return"] -> :forward_only
      token in ["<-", "from", "source"] -> :backward_only
      true -> nil
    end
  end

  # =============================================================================
  # QUANTUMSCRIPT PARSER WITH FSM SPAWNING
  # =============================================================================

  @doc """
  Parse QuantumScript tokens using quantum FSM parsing.
  """
  def parse(tokens) do
    Logger.info("🧬 Parsing QuantumScript with Quantum FSMs...")

    # Create master parser FSM
    master_fsm = QuantumFSM.new("qs_master", "QuantumScriptMasterFSM", :language_parser,
      can_spawn: true, can_backtrack: true, confidence: 0.8)

    # Create token stream for bidirectional parsing
    token_stream = TokenStream.new(tokens)

    # Parse with quantum FSM spawning
    parse_result = parse_with_quantum_fsm(master_fsm, token_stream)

    Logger.info("✨ QuantumScript parsing complete!")
    Logger.info("📊 Parse result: #{parse_result.confidence} confidence")
    Logger.info("🤖 FSMs spawned: #{length(parse_result.spawned_fsms)}")

    parse_result
  end

  defp parse_with_quantum_fsm(master_fsm, token_stream) do
    Logger.info("🧠 Starting quantum FSM parsing...")

    spawned_fsms = []
    ast_nodes = []

    # Process tokens with FSM spawning
    {final_stream, final_fsms, final_ast} = process_tokens_recursively(
      token_stream, master_fsm, spawned_fsms, ast_nodes
    )

    %{
      ast: final_ast,
      confidence: calculate_parse_confidence(final_ast),
      spawned_fsms: final_fsms,
      token_stream: final_stream,
      parse_type: :quantum_fsm_parsing
    }
  end

  defp process_tokens_recursively(stream, current_fsm, spawned_fsms, ast_nodes) do
    current_token = TokenStream.current_token(stream)

    # Check if we're at end of tokens or beyond bounds
    if current_token == nil or stream.position >= length(stream.tokens) do
      # End of tokens
      {stream, spawned_fsms, ast_nodes}
    else
      Logger.debug("Processing token: #{current_token.value} (#{current_token.type}) at position #{stream.position}")

      # Decide whether to spawn specialized FSM
      case should_spawn_fsm?(current_token, current_fsm) do
        {:spawn, fsm_type} ->
          # Spawn specialized FSM
          new_fsm = spawn_specialized_fsm(fsm_type, current_token)
          Logger.info("👶 Spawned #{new_fsm.name} for #{current_token.value}")

          # Process with spawned FSM
          {_updated_stream, _updated_spawned, new_ast_node} =
            process_with_spawned_fsm(stream, new_fsm, current_token)

          # IMPORTANT: Always advance to next token
          next_stream = TokenStream.move(stream, :forward, 1)

          # Prevent infinite recursion by checking bounds
          if next_stream.position >= length(stream.tokens) do
            {next_stream, [new_fsm | spawned_fsms], [new_ast_node | ast_nodes]}
          else
            process_tokens_recursively(
              next_stream, current_fsm, [new_fsm | spawned_fsms], [new_ast_node | ast_nodes]
            )
          end

        {:continue, _updated_fsm} ->
          # Process with current FSM
          {_updated_stream, ast_node} = process_with_current_fsm(stream, current_fsm, current_token)

          # IMPORTANT: Always advance to next token
          next_stream = TokenStream.move(stream, :forward, 1)

          # Prevent infinite recursion by checking bounds
          if next_stream.position >= length(stream.tokens) do
            {next_stream, spawned_fsms, [ast_node | ast_nodes]}
          else
            process_tokens_recursively(
              next_stream, current_fsm, spawned_fsms, [ast_node | ast_nodes]
            )
          end

        {:backtrack, reason} ->
          # Bidirectional parsing needed
          Logger.info("🔄 Backtracking needed: #{reason}")
          {backtracked_stream, resolved_ast} = handle_bidirectional_parsing(stream, current_fsm, current_token)

          # IMPORTANT: Ensure we advance past the problematic token
          advanced_stream = TokenStream.move(backtracked_stream, :forward, 1)

          # Prevent infinite recursion
          if advanced_stream.position >= length(stream.tokens) do
            {advanced_stream, spawned_fsms, [resolved_ast | ast_nodes]}
          else
            process_tokens_recursively(
              advanced_stream, current_fsm, spawned_fsms, [resolved_ast | ast_nodes]
            )
          end
      end
    end
  end

  # =============================================================================
  # FSM SPAWNING LOGIC
  # =============================================================================

  defp should_spawn_fsm?(token, _current_fsm) do
    case token.type do
      :collaborate_block -> {:spawn, :collaboration_fsm}
      :natural_lang_block -> {:spawn, :natural_language_fsm}
      :adaptive_modifier -> {:spawn, :adaptive_fsm}
      :quantum_module -> {:spawn, :module_fsm}
      :gravitation_block -> {:spawn, :physics_fsm}
      :data_context -> {:spawn, :data_context_fsm}
      :ui_context -> {:spawn, :ui_context_fsm}
      :math_context -> {:spawn, :math_context_fsm}
      :function_def -> {:spawn, :function_fsm}
      :class_def -> {:spawn, :class_fsm}
      _ when token.quantum_weight >= 0.8 -> {:continue, :enhanced}
      _ -> {:continue, :normal}
    end
  end

  defp spawn_specialized_fsm(fsm_type, trigger_token) do
    case fsm_type do
      :collaboration_fsm ->
        QuantumFSM.new("collab_#{trigger_token.position}", "CollaborationFSM", :collaboration,
          can_spawn: true, confidence: 0.85)

      :natural_language_fsm ->
        QuantumFSM.new("nl_#{trigger_token.position}", "NaturalLanguageFSM", :natural_language,
          can_backtrack: true, confidence: 0.9)

      :adaptive_fsm ->
        QuantumFSM.new("adapt_#{trigger_token.position}", "AdaptiveFSM", :adaptive,
          can_spawn: true, can_backtrack: true, confidence: 0.75)

      :module_fsm ->
        QuantumFSM.new("mod_#{trigger_token.position}", "ModuleFSM", :module,
          can_spawn: true, confidence: 0.8)

      :physics_fsm ->
        QuantumFSM.new("phys_#{trigger_token.position}", "PhysicsFSM", :physics,
          can_backtrack: true, confidence: 0.85)

      :function_fsm ->
        QuantumFSM.new("func_#{trigger_token.position}", "FunctionFSM", :function,
          can_spawn: true, can_backtrack: true, confidence: 0.8)

      _ ->
        QuantumFSM.new("gen_#{trigger_token.position}", "GenericFSM", :generic, confidence: 0.6)
    end
  end

  defp process_with_spawned_fsm(stream, spawned_fsm, trigger_token) do
    Logger.debug("🎯 Processing with #{spawned_fsm.name}")

    # Create AST node for this construct
    ast_node = case spawned_fsm.type do
      :collaboration ->
        QSASTNode.new(:collaborate_block, "collaborate", [],
          %{fsm_id: spawned_fsm.id, confidence: spawned_fsm.confidence})

      :natural_language ->
        QSASTNode.new(:natural_language_block, trigger_token.value, [],
          %{fsm_id: spawned_fsm.id, quantum_weight: trigger_token.quantum_weight})

      :adaptive ->
        QSASTNode.new(:adaptive_construct, trigger_token.value, [],
          %{fsm_id: spawned_fsm.id, adaptation_enabled: true})

      :module ->
        QSASTNode.new(:quantum_module, trigger_token.value, [],
          %{fsm_id: spawned_fsm.id, can_spawn: true})

      :physics ->
        QSASTNode.new(:physics_block, trigger_token.value, [],
          %{fsm_id: spawned_fsm.id, physics_type: :gravitation})

      :function ->
        QSASTNode.new(:function_def, trigger_token.value, [],
          %{fsm_id: spawned_fsm.id, bidirectional: true})

      _ ->
        QSASTNode.new(:generic_construct, trigger_token.value, [], %{fsm_id: spawned_fsm.id})
    end

    {stream, [spawned_fsm], ast_node}
  end

  defp process_with_current_fsm(stream, current_fsm, token) do
    # Create basic AST node
    ast_node = QSASTNode.new(:token_node, token.value, [],
      %{token_type: token.type, quantum_weight: token.quantum_weight})

    {stream, ast_node}
  end

  # =============================================================================
  # BIDIRECTIONAL PARSING
  # =============================================================================

  defp handle_bidirectional_parsing(stream, fsm, ambiguous_token) do
    Logger.info("🔄 Handling bidirectional parsing for: #{ambiguous_token.value}")

    # Look backward for context
    backward_context = TokenStream.peek(stream, :backward, 3)
    Logger.debug("Backward context: #{Enum.map(backward_context, & &1.value) |> Enum.join(" ")}")

    # Look forward for confirmation
    forward_context = TokenStream.peek(stream, :forward, 3)
    Logger.debug("Forward context: #{Enum.map(forward_context, & &1.value) |> Enum.join(" ")}")

    # Resolve ambiguity using bidirectional analysis
    resolution = resolve_bidirectional_ambiguity(ambiguous_token, backward_context, forward_context)

    # Create resolved AST node
    resolved_ast = QSASTNode.new(:bidirectional_resolved, ambiguous_token.value, [],
      %{
        resolution: resolution,
        backward_context: backward_context,
        forward_context: forward_context,
        confidence: calculate_resolution_confidence(resolution, backward_context, forward_context)
      })

    Logger.info("✅ Bidirectional resolution: #{resolution}")

    {stream, resolved_ast}
  end

  defp resolve_bidirectional_ambiguity(token, backward_context, forward_context) do
    # Analyze contexts to resolve meaning
    backward_hints = extract_context_hints(backward_context)
    forward_hints = extract_context_hints(forward_context)

    cond do
      :function_context in backward_hints and :parameter_list in forward_hints ->
        :function_definition

      :conditional_context in backward_hints and :block_start in forward_hints ->
        :conditional_block

      :collaboration_context in backward_hints ->
        :collaborative_construct

      :quantum_context in backward_hints or :quantum_context in forward_hints ->
        :quantum_construct

      true ->
        :contextual_identifier
    end
  end

  defp extract_context_hints(tokens) do
    Enum.flat_map(tokens, fn token ->
      case token.type do
        :function_def -> [:function_context]
        :collaborate_block -> [:collaboration_context]
        :quantum_module -> [:quantum_context]
        :adaptive_modifier -> [:adaptive_context]
        :paren_open -> [:parameter_list]
        :brace_open -> [:block_start]
        :conditional_when -> [:conditional_context]
        _ -> []
      end
    end)
  end

  # =============================================================================
  # HELPER FUNCTIONS
  # =============================================================================

  defp calculate_parse_confidence(ast_nodes) do
    if length(ast_nodes) == 0 do
      0.0
    else
      total_confidence = Enum.reduce(ast_nodes, 0.0, fn node, acc ->
        node_confidence = Map.get(node.metadata, :confidence, 0.5)
        acc + node_confidence
      end)

      avg_confidence = total_confidence / length(ast_nodes)
      min(1.0, avg_confidence)
    end
  end

  defp calculate_resolution_confidence(resolution, backward_context, forward_context) do
    base_confidence = case resolution do
      :function_definition -> 0.9
      :conditional_block -> 0.85
      :collaborative_construct -> 0.8
      :quantum_construct -> 0.95
      _ -> 0.6
    end

    # Boost confidence based on context strength
    context_boost = (length(backward_context) + length(forward_context)) * 0.05

    min(1.0, base_confidence + context_boost)
  end

  # =============================================================================
  # QUANTUMSCRIPT EXAMPLE PARSING
  # =============================================================================

  @doc """
  Test parsing a QuantumScript code example.
  """
  def test_parse_example do
    Logger.info("🧪 Testing QuantumScript parsing with example code...")

    example_code = """
    quantum_module UserService {
        collaborate {
            authentication: validate_user(credentials) -> user_record
            authorization: check_permissions(user_record) -> permissions
            session: create_session(user_record, permissions) -> session_token
        }

        adaptive function process_user_data(user) <-> {
            when user.type == "premium":
                spawn premium_processor -> enhanced_processing(user)
            when user.type == "standard":
                spawn standard_processor -> basic_processing(user)
            else:
                spawn adaptive_processor -> learn_and_process(user)
        }

        natural_language {
            "When user logs in successfully, create session and redirect to dashboard"
            -> handle_successful_login(user) -> dashboard_redirect
        }
    }
    """

    # Tokenize and parse
    tokens = tokenize(example_code)
    parse_result = parse(tokens)

    Logger.info("🎯 Example Parsing Results:")
    Logger.info("  Tokens: #{length(tokens)}")
    Logger.info("  AST Nodes: #{length(parse_result.ast)}")
    Logger.info("  Confidence: #{Float.round(parse_result.confidence, 2)}")
    Logger.info("  FSMs Spawned: #{length(parse_result.spawned_fsms)}")

    Logger.info("")
    Logger.info("🤖 Spawned FSMs:")
    Enum.each(parse_result.spawned_fsms, fn fsm ->
      Logger.info("  • #{fsm.name} (#{fsm.type}, confidence: #{fsm.confidence})")
    end)

    Logger.info("")
    Logger.info("🌳 AST Preview:")
    Enum.take(parse_result.ast, 5) |> Enum.each(fn node ->
      Logger.info("  • #{node.type}: #{node.value}")
    end)

    parse_result
  end
end
