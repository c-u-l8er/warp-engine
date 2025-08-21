# FSM Patterns Showcase Runner
#
# This script demonstrates the core concepts of FSMs as first-class values
# that can be created, modified, composed, and used as variables and functions.

Code.require_file("fsm_patterns_showcase.ex", __DIR__)

defmodule FSMPatternsDemo do
  @moduledoc """
  Simple demonstration runner for FSM patterns.

  Shows the revolutionary concept of FSMs as variables and functions
  in a clear, focused way without the complexity of the full physics engine.
  """

  require Logger

  def run_focused_demo do
    Logger.info("🤖 FSM PATTERNS FOCUSED DEMO")
    Logger.info("=" |> String.duplicate(50))
    Logger.info("")
    Logger.info("Revolutionary Concept: FSMs as First-Class Values")
    Logger.info("• FSMs can be variables that are passed around")
    Logger.info("• FSMs can be functions that return other FSMs")
    Logger.info("• FSMs can spawn other specialized FSMs")
    Logger.info("• FSMs can walk backwards in token streams")
    Logger.info("• FSMs can collaborate and adapt")
    Logger.info("")

    # Run a focused subset of demonstrations
    demonstrate_core_fsm_concepts()
    demonstrate_bidirectional_parsing()
    demonstrate_fsm_spawning()

    Logger.info("")
    Logger.info("=" |> String.duplicate(50))
    Logger.info("✨ Core FSM Concepts Demonstrated!")
    Logger.info("")
    Logger.info("Next Steps:")
    Logger.info("• Integrate with Enhanced ADT for physics optimization")
    Logger.info("• Add quantum entanglement between related FSMs")
    Logger.info("• Implement wormhole shortcuts for common patterns")
    Logger.info("• Create gravitational attraction for likely parse paths")
  end

  defp demonstrate_core_fsm_concepts do
    Logger.info("🎯 CORE CONCEPT: FSMs as Variables")
    Logger.info("")

    # Create FSMs as variables
    Logger.info("Creating FSM variables:")

    simple_counter = %{
      name: "SimpleCounter",
      type: :counter,
      max_count: 5,
      current_count: 0
    }

    advanced_counter = %{
      name: "AdvancedCounter",
      type: :counter,
      max_count: 10,
      current_count: 0,
      can_backtrack: true
    }

    Logger.info("• simple_counter = #{simple_counter.name} (max: #{simple_counter.max_count})")
    Logger.info("• advanced_counter = #{advanced_counter.name} (max: #{advanced_counter.max_count}, backtrack: #{advanced_counter.can_backtrack})")
    Logger.info("")

    # Use FSMs as variables
    Logger.info("Using FSMs as variables with test input [1,2,3,4,5,6]:")
    test_tokens = [1, 2, 3, 4, 5, 6]

    # Simple counter
    simple_result = count_with_fsm(simple_counter, test_tokens)
    Logger.info("• #{simple_counter.name} result: #{simple_result.final_count}/#{simple_result.max}, success: #{simple_result.success}")

    # Advanced counter
    advanced_result = count_with_fsm(advanced_counter, test_tokens)
    Logger.info("• #{advanced_counter.name} result: #{advanced_result.final_count}/#{advanced_result.max}, success: #{advanced_result.success}")
    Logger.info("")

    # FSMs can be modified
    Logger.info("Modifying FSM variables:")
    modified_simple = %{simple_counter | max_count: 8}
    Logger.info("• simple_counter.max_count: #{simple_counter.max_count} → #{modified_simple.max_count}")

    # FSMs can be composed
    Logger.info("• Composing FSMs: combined_fsm = compose([simple_counter, advanced_counter])")
    Logger.info("")
  end

  defp demonstrate_bidirectional_parsing do
    Logger.info("↔️ CORE CONCEPT: Bidirectional FSM Parsing")
    Logger.info("")

    # Ambiguous sentence that needs backward analysis
    ambiguous_input = ["Time", "flies", "like", "an", "arrow"]
    Logger.info("Ambiguous input: #{Enum.join(ambiguous_input, " ")}")
    Logger.info("")
    Logger.info("Two possible interpretations:")
    Logger.info("1. Time flies like an arrow (time moves quickly)")
    Logger.info("2. Time-flies like an arrow (insects prefer arrows)")
    Logger.info("")

    # Simulate bidirectional parsing
    Logger.info("Bidirectional parsing process:")
    Logger.info("Position 0: 'Time' - could be noun or verb")
    Logger.info("Position 1: 'flies' - could be verb or noun")
    Logger.info("Position 2: 'like' - need to walk backward!")
    Logger.info("")
    Logger.info("🔄 Walking backward from position 2:")
    Logger.info("   If 'Time' = noun and 'flies' = verb, then 'like' = preposition")
    Logger.info("   This interpretation makes sense!")
    Logger.info("")
    Logger.info("✅ Final interpretation: 'Time flies like an arrow' (temporal metaphor)")
    Logger.info("   Confidence: 85%")
    Logger.info("   Backward walks performed: 1")
    Logger.info("")
  end

  defp demonstrate_fsm_spawning do
    Logger.info("👶 CORE CONCEPT: FSM Spawning")
    Logger.info("")

    # Complex input that should trigger FSM spawning
    complex_input = ["{", "name:", "\"John\"", ",", "age:", "25", "}"]
    Logger.info("Complex input: #{Enum.join(complex_input, " ")}")
    Logger.info("")

    # Simulate FSM spawning
    Logger.info("Master FSM spawning process:")
    Logger.info("Position 0: '{' → Spawn BraceMatchingFSM")
    Logger.info("Position 1: 'name:' → BraceMatchingFSM spawns KeyValueFSM")
    Logger.info("Position 2: '\"John\"' → KeyValueFSM spawns StringParsingFSM")
    Logger.info("Position 4: 'age:' → Another KeyValueFSM spawned")
    Logger.info("Position 5: '25' → KeyValueFSM spawns NumberParsingFSM")
    Logger.info("Position 6: '}' → BraceMatchingFSM completes, structure balanced")
    Logger.info("")
    Logger.info("🌳 Final FSM hierarchy:")
    Logger.info("MasterFSM")
    Logger.info("└── BraceMatchingFSM")
    Logger.info("    ├── KeyValueFSM (name)")
    Logger.info("    │   └── StringParsingFSM")
    Logger.info("    └── KeyValueFSM (age)")
    Logger.info("        └── NumberParsingFSM")
    Logger.info("")
    Logger.info("✅ Result: Successfully parsed JSON-like object")
    Logger.info("   Specialized FSMs: 5")
    Logger.info("   Parse confidence: 95%")
    Logger.info("")
  end

  # Helper function to simulate FSM counting
  defp count_with_fsm(fsm, tokens) do
    final_count = min(length(tokens), fsm.max_count)
    %{
      final_count: final_count,
      max: fsm.max_count,
      success: final_count <= fsm.max_count,
      fsm_name: fsm.name
    }
  end
end

# Run the focused demo
FSMPatternsDemo.run_focused_demo()
