defmodule ServiceWarp.AutogenticLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "autogentic_logs" do
    field :event, :string
    field :source, :string, default: "autogentic"
    field :session_id, :string
    field :level, :string
    field :payload, :map

    timestamps(type: :naive_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:event, :source, :session_id, :level, :payload])
    |> validate_required([:event, :source])
  end
end
