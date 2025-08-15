defmodule IsLabDB.EntropyRegistry do
  @moduledoc """
  Registry for Entropy Monitors in the IsLab Database system.

  This registry maintains references to all active entropy monitoring
  processes and provides lookup functionality for the entropy system.
  """

  def child_spec(_) do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__
    )
  end
end
