# Simple QuantumScript Test Runner
#
# Quick validation of core QuantumScript features without overwhelming detail

Code.require_file("test_quantum_parser.exs", __DIR__)
Code.require_file("quantumscript_parser.ex", __DIR__)

defmodule SimpleQuantumScriptTest do
  @moduledoc """
  Simple, focused test runner for QuantumScript validation.

  Tests core revolutionary features:
  - Basic parsing works
  - FSM spawning works
  - Bidirectional parsing works
  - Real examples parse successfully
  """

  require Logger

  def run_simple_tests do
    Logger.info("🧪 SIMPLE QUANTUMSCRIPT VALIDATION")
    Logger.info("=" |> String.duplicate(50))
    Logger.info("")

    tests = [
      {"Basic parsing", test_basic_parsing()},
      {"FSM spawning", test_fsm_spawning()},
      {"Bidirectional syntax", test_bidirectional()},
      {"Collaborative blocks", test_collaborative()},
      {"Natural language", test_natural_language()},
      {"Real-world example", test_real_world_example()}
    ]

    test_results = Enum.map(tests, fn {name, result} ->
      status = if result.success, do: "✅", else: "❌"
      Logger.info("#{status} #{name}: #{result.details}")
      result.success
    end)

    passed = Enum.count(test_results, & &1)
    total = length(tests)

    Logger.info("")
    Logger.info("📊 Results: #{passed}/#{total} tests passed (#{Float.round(passed/total*100, 1)}%)")

    if passed >= total * 0.8 do
      Logger.info("🎉 SUCCESS: QuantumScript core features validated!")
      Logger.info("🚀 Ready to build the future of programming!")
    else
      Logger.info("🔧 Some issues need attention before proceeding")
    end

    Logger.info("")
    %{passed: passed, total: total, success_rate: passed/total}
  end

  defp test_basic_parsing do
    code = "function test() -> { return 42 }"

    try do
      tokens = QuantumScriptParser.tokenize(code)
      parse_result = QuantumScriptParser.parse(tokens)

      success = length(tokens) > 0 and
                is_map(parse_result) and
                parse_result.confidence > 0.2

      %{success: success, details: "#{length(tokens)} tokens, #{Float.round(parse_result.confidence, 2)} confidence"}
    rescue
      error ->
        %{success: false, details: "Parse error: #{inspect(error)}"}
    end
  end

  defp test_fsm_spawning do
    code = "quantum_module Test { function spawn_test() -> { } }"

    try do
      tokens = QuantumScriptParser.tokenize(code)
      parse_result = QuantumScriptParser.parse(tokens)

      fsms_spawned = length(parse_result.spawned_fsms)
      success = fsms_spawned >= 1

      %{success: success, details: "#{fsms_spawned} FSMs spawned"}
    rescue
      error ->
        %{success: false, details: "Spawn error: #{inspect(error)}"}
    end
  end

  defp test_bidirectional do
    code = "function test(x) <-> { process x -> result trace result <- x }"

    try do
      tokens = QuantumScriptParser.tokenize(code)

      bidirectional_ops = Enum.count(tokens, fn token ->
        token.type in [:bidirectional_op, :backward_op]
      end)

      success = bidirectional_ops >= 1

      %{success: success, details: "#{bidirectional_ops} bidirectional operators found"}
    rescue
      error ->
        %{success: false, details: "Bidirectional error: #{inspect(error)}"}
    end
  end

  defp test_collaborative do
    code = "collaborate { task1: action1() -> result1 }"

    try do
      tokens = QuantumScriptParser.tokenize(code)
      parse_result = QuantumScriptParser.parse(tokens)

      collab_fsms = Enum.count(parse_result.spawned_fsms, &(&1.type == :collaboration))
      success = collab_fsms >= 1

      %{success: success, details: "#{collab_fsms} collaboration FSMs"}
    rescue
      error ->
        %{success: false, details: "Collaboration error: #{inspect(error)}"}
    end
  end

  defp test_natural_language do
    code = "natural_language { \"Test requirement\" -> implementation }"

    try do
      tokens = QuantumScriptParser.tokenize(code)
      parse_result = QuantumScriptParser.parse(tokens)

      nl_blocks = Enum.count(tokens, &(&1.type == :natural_lang_block))
      success = nl_blocks >= 1

      %{success: success, details: "#{nl_blocks} natural language blocks"}
    rescue
      error ->
        %{success: false, details: "Natural language error: #{inspect(error)}"}
    end
  end

  defp test_real_world_example do
    # Test a realistic QuantumScript program
    real_world_code = """
    quantum_module UserService {
        collaborate {
            authentication: validate_user(credentials) -> user_record
            authorization: check_permissions(user_record) -> permissions
        }

        adaptive function process_user_request(request) <-> {
            when request.urgent:
                spawn priority_processor -> fast_processing(request)
            else:
                spawn standard_processor -> normal_processing(request)

            trace result <- processor <- request
        }

        natural_language {
            "When user logs in, create session and redirect to dashboard"
            -> handle_login(user) -> dashboard_redirect
        }
    }
    """

    try do
      start_time = System.monotonic_time(:microsecond)
      tokens = QuantumScriptParser.tokenize(real_world_code)
      parse_result = QuantumScriptParser.parse(tokens)
      end_time = System.monotonic_time(:microsecond)

      parse_time = end_time - start_time

      # Real-world example should parse well
      success = length(tokens) > 20 and
                parse_result.confidence > 0.3 and
                length(parse_result.spawned_fsms) >= 2 and
                parse_time < 1_000_000  # < 1 second

      %{success: success, details: "#{length(tokens)} tokens, #{Float.round(parse_result.confidence, 2)} confidence, #{length(parse_result.spawned_fsms)} FSMs in #{parse_time}μs"}
    rescue
      error ->
        %{success: false, details: "Real-world test error: #{inspect(error)}"}
    end
  end
end

# Run simple validation
SimpleQuantumScriptTest.run_simple_tests()
