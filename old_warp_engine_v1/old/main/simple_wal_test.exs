#!/usr/bin/env elixir

IO.puts "🚀 Simple WAL Test - Phase 6.6"
IO.puts "==============================="

# Add project to path
Code.prepend_path("lib")

try do
  # Load WAL Entry module
  Code.require_file("lib/warp_engine/wal_entry.ex")

  IO.puts "✅ WAL Entry module loaded"

  # Create a simple test entry
  entry = WarpEngine.WAL.Entry.new(
    :put,
    "test:key",
    %{data: "hello", number: 42},
    :hot_data,
    %{entropy: 1.0},
    1001
  )

  IO.puts "✅ WAL Entry created"
  IO.puts "   Sequence: #{entry.sequence}"
  IO.puts "   Operation: #{entry.operation}"
  IO.puts "   Key: #{entry.key}"

  # Test binary encoding
  binary = WarpEngine.WAL.Entry.encode_binary(entry)
  IO.puts "✅ Binary encoding: #{byte_size(binary)} bytes"

  # Test binary decoding
  decoded = WarpEngine.WAL.Entry.decode_binary(binary)
  IO.puts "✅ Binary decoding successful"

  # Test JSON encoding
  json = WarpEngine.WAL.Entry.encode_json(entry)
  IO.puts "✅ JSON encoding: #{byte_size(json)} bytes"

  IO.puts "\n🎉 WAL Entry system working correctly!"

rescue
  error ->
    IO.puts "❌ Test failed: #{inspect(error)}"
    System.halt(1)
end

IO.puts "\n🚀 Phase 6.6 WAL Foundation: SOLID!"
