defmodule WarpEngine.WAL.Entry do
  @moduledoc """
  WAL Entry structure for high-performance operation logging.

  Defines the format for Write-Ahead Log entries that capture all
  database operations while maintaining physics intelligence metadata.

  ## Design Principles

  - **Hybrid Format**: Binary for speed, JSON for debugging
  - **Physics Preservation**: Complete cosmic metadata included
  - **Compression**: Large values compressed automatically
  - **Versioning**: Forward/backward compatibility

  ## Entry Structure

  Each WAL entry contains:
  - Sequence number for ordering
  - High-precision timestamp
  - Operation type (:put, :get, :delete)
  - Spacetime shard information
  - Data key and value
  - Complete physics metadata
  """

  # Jason.Encoder derivation removed for compatibility - will be added back when Jason is available

  defstruct [
    :sequence,           # Unique sequence number for ordering
    :timestamp,          # Microsecond timestamp
    :operation,          # :put, :get, :delete, :quantum_get
    :shard_id,           # Spacetime shard identifier
    :key,                # Data key
    :value,              # Data value (may be compressed)
    :value_preview,      # Small preview for JSON debugging
    :physics_metadata,   # Complete cosmic metadata
    :compression_type,   # :none, :gzip, :lz4
    :version,            # Entry format version
    :checksum            # Data integrity verification
  ]

  # Entry format version for compatibility
  @current_version "6.6.0"

  # Compression thresholds
  @compression_threshold_bytes 1024
  @preview_max_length 100

  @doc """
  Create a new WAL entry from operation parameters.
  """
  def new(operation_type, key, value, shard_id, physics_metadata, sequence) do
    timestamp = :os.system_time(:microsecond)

    # Compress large values for efficiency
    {final_value, compression_type} = compress_if_large(value)

    # Create value preview for JSON debugging
    value_preview = create_value_preview(value)

    # Calculate checksum for integrity
    checksum = calculate_checksum(key, final_value, physics_metadata)

    entry = %__MODULE__{
      sequence: sequence,
      timestamp: timestamp,
      operation: operation_type,
      shard_id: shard_id,
      key: key,
      value: final_value,
      value_preview: value_preview,
      physics_metadata: physics_metadata,
      compression_type: compression_type,
      version: @current_version,
      checksum: checksum
    }

    entry
  end

  @doc """
  Encode entry to binary format for maximum I/O performance.

  Binary format structure:
  - Version (8 bytes)
  - Sequence (8 bytes)
  - Timestamp (8 bytes)
  - Operation type (1 byte)
  - Compression type (1 byte)
  - Key length + key data
  - Value length + value data
  - Physics metadata length + metadata
  - Checksum (16 bytes)
  """
  def encode_binary(entry) do
    key_binary = :erlang.term_to_binary(entry.key)
    value_binary = entry.value
    metadata_binary = :erlang.term_to_binary(entry.physics_metadata)

    operation_byte = operation_to_byte(entry.operation)
    compression_byte = compression_to_byte(entry.compression_type)

    # Build binary entry
    <<
      entry.sequence::64,
      entry.timestamp::64,
      operation_byte::8,
      compression_byte::8,
      byte_size(key_binary)::32,
      key_binary::binary,
      byte_size(value_binary)::32,
      value_binary::binary,
      byte_size(metadata_binary)::32,
      metadata_binary::binary,
      entry.checksum::128
    >>
  end

  @doc """
  Decode entry from binary format.
  """
  def decode_binary(binary_data) do
    <<
      sequence::64,
      timestamp::64,
      operation_byte::8,
      compression_byte::8,
      key_size::32,
      key_binary::binary-size(key_size),
      value_size::32,
      value_binary::binary-size(value_size),
      metadata_size::32,
      metadata_binary::binary-size(metadata_size),
      checksum::128,
      _rest::binary
    >> = binary_data

    key = :erlang.binary_to_term(key_binary)
    physics_metadata = :erlang.binary_to_term(metadata_binary)
    operation = byte_to_operation(operation_byte)
    compression_type = byte_to_compression(compression_byte)

    # Decompress value if needed
    final_value = decompress_value(value_binary, compression_type)

    %__MODULE__{
      sequence: sequence,
      timestamp: timestamp,
      operation: operation,
      key: key,
      value: final_value,
      physics_metadata: physics_metadata,
      compression_type: compression_type,
      version: @current_version,
      checksum: checksum
    }
  end

  @doc """
  Encode entry to JSON format for human-readable debugging.
  """
  def encode_json(entry) do
    # Manual JSON encoding for compatibility - handle both full and minimal entries
    json_map = %{
      sequence: Map.get(entry, :sequence),
      timestamp: Map.get(entry, :timestamp),
      operation: Map.get(entry, :operation),
      shard_id: Map.get(entry, :shard_id),
      key: Map.get(entry, :key),
      value_preview: Map.get(entry, :value_preview),
      physics_metadata: Map.get(entry, :physics_metadata, %{}),
      compression_type: Map.get(entry, :compression_type, :none),
      version: Map.get(entry, :version, "6.6.0")
    }

    # Simple JSON encoding (will be replaced with proper Jason when available)
    inspect(json_map, pretty: true)
  end

  @doc """
  Decode entry from JSON format.
  """
  def decode_json(_json_data) do
    # JSON decoding not implemented without Jason
    {:error, "JSON decoding requires Jason library"}
  end

  @doc """
  Validate entry integrity using checksum.
  """
  def validate_integrity(entry) do
    expected_checksum = calculate_checksum(entry.key, entry.value, entry.physics_metadata)
    entry.checksum == expected_checksum
  end

  @doc """
  Get entry size in bytes (for statistics and monitoring).
  """
  def entry_byte_size(entry) do
    key_size = :erlang.size(:erlang.term_to_binary(entry.key))
    value_size = if is_binary(entry.value), do: byte_size(entry.value), else: :erlang.size(:erlang.term_to_binary(entry.value))
    metadata_size = :erlang.size(:erlang.term_to_binary(entry.physics_metadata))

    # Header overhead (sequence, timestamp, operation, etc.)
    header_size = 64

    header_size + key_size + value_size + metadata_size
  end

  ## PRIVATE FUNCTIONS

  defp compress_if_large(value) do
    value_binary = if is_binary(value), do: value, else: :erlang.term_to_binary(value)

    if byte_size(value_binary) > @compression_threshold_bytes do
      compressed = :zlib.gzip(value_binary)
      {compressed, :gzip}
    else
      {value_binary, :none}
    end
  end

  defp decompress_value(value_binary, :gzip) do
    decompressed = :zlib.gunzip(value_binary)

    # Try to decode as Erlang term, otherwise keep as binary
    try do
      :erlang.binary_to_term(decompressed)
    catch
      _, _ -> decompressed
    end
  end

  defp decompress_value(value_binary, :none) do
    # Try to decode as Erlang term, otherwise keep as binary
    try do
      :erlang.binary_to_term(value_binary)
    catch
      _, _ -> value_binary
    end
  end

  defp create_value_preview(value) do
    preview = inspect(value, limit: @preview_max_length, printable_limit: @preview_max_length)

    if String.length(preview) > @preview_max_length do
      String.slice(preview, 0, @preview_max_length) <> "..."
    else
      preview
    end
  end

  defp calculate_checksum(key, value, physics_metadata) do
    # Create hash of critical data for integrity verification
    data_to_hash = [
      :erlang.term_to_binary(key),
      if(is_binary(value), do: value, else: :erlang.term_to_binary(value)),
      :erlang.term_to_binary(physics_metadata)
    ]

    combined_data = Enum.join(data_to_hash)
    :crypto.hash(:md5, combined_data)
    |> :binary.decode_unsigned()
  end

  defp operation_to_byte(:put), do: 1
  defp operation_to_byte(:get), do: 2
  defp operation_to_byte(:delete), do: 3
  defp operation_to_byte(:quantum_get), do: 4
  defp operation_to_byte(_), do: 0

  defp byte_to_operation(1), do: :put
  defp byte_to_operation(2), do: :get
  defp byte_to_operation(3), do: :delete
  defp byte_to_operation(4), do: :quantum_get
  defp byte_to_operation(_), do: :unknown

  defp compression_to_byte(:none), do: 0
  defp compression_to_byte(:gzip), do: 1
  defp compression_to_byte(:lz4), do: 2
  defp compression_to_byte(_), do: 0

  defp byte_to_compression(0), do: :none
  defp byte_to_compression(1), do: :gzip
  defp byte_to_compression(2), do: :lz4
  defp byte_to_compression(_), do: :none

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
  defp atomize_keys(value), do: value
end
