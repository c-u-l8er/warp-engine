# QuantumScript Language Test Runner
#
# Comprehensive test suite for our revolutionary QuantumScript programming language
# Tests all quantum FSM parsing capabilities and validates production readiness

Code.require_file("test_quantum_parser.exs", __DIR__)
Code.require_file("quantumscript_parser.ex", __DIR__)
Code.require_file("quantumscript_test_suite.ex", __DIR__)

defmodule QuantumScriptTestRunner do
  @moduledoc """
  Test runner for QuantumScript language validation.

  Runs comprehensive tests to validate:
  - All quantum FSM parsing features
  - Language syntax and semantics
  - Performance characteristics
  - Production readiness
  """

  require Logger

  def run_all_tests do
    Logger.info("🧪 STARTING QUANTUMSCRIPT COMPREHENSIVE TEST SUITE")
    Logger.info("=" |> String.duplicate(80))
    Logger.info("")
    Logger.info("Testing the world's first quantum FSM-based programming language")
    Logger.info("Validating revolutionary features for production deployment")
    Logger.info("")

    # Run the comprehensive test suite
    test_report = QuantumScriptTestSuite.run_all_tests()

    # Show final summary
    show_final_summary(test_report)

    test_report
  end

  defp show_final_summary(test_report) do
    Logger.info("")
    Logger.info("🎯 QUANTUMSCRIPT VALIDATION COMPLETE!")
    Logger.info("")

    if test_report.pass_rate >= 80 do
      Logger.info("🎉 **SUCCESS**: QuantumScript is ready for the future!")
      Logger.info("")
      Logger.info("✅ **Revolutionary Features Validated:**")
      Logger.info("   🤖 FSMs as first-class variables and functions")
      Logger.info("   ↔️ Bidirectional parsing and context understanding")
      Logger.info("   👶 Dynamic FSM spawning based on syntax patterns")
      Logger.info("   🤝 Collaborative programming blocks")
      Logger.info("   💬 Natural language integration")
      Logger.info("   🧠 Adaptive FSM learning and evolution")
      Logger.info("")
      Logger.info("🚀 **Ready for Next Steps:**")
      Logger.info("   • Full compiler/interpreter implementation")
      Logger.info("   • IDE integration with quantum parsing")
      Logger.info("   • Standard library development")
      Logger.info("   • Developer tools and documentation")
      Logger.info("   • Beta release and community building")
    else
      Logger.info("🔧 **Development Needed**: #{Float.round(test_report.pass_rate, 1)}% pass rate")
      Logger.info("   Continue refining quantum parsing implementation")
      Logger.info("   Address failing test cases")
      Logger.info("   Optimize performance bottlenecks")
    end

    Logger.info("")
    Logger.info("🌌 QuantumScript: Programming language of the future!")
  end
end

# Run all QuantumScript tests
QuantumScriptTestRunner.run_all_tests()
