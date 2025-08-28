defmodule WarpWebTest do
  use ExUnit.Case
  doctest WarpWeb

  test "WarpWeb module exists and has expected functions" do
    # Test that the WarpWeb module exists and has the expected structure
    assert Code.ensure_loaded(WarpWeb)
    
    # Test that the module provides the expected contexts
    assert function_exported?(WarpWeb, :controller, 0)
    assert function_exported?(WarpWeb, :html, 0)
    assert function_exported?(WarpWeb, :live_view, 0)
    assert function_exported?(WarpWeb, :router, 0)
  end
end
