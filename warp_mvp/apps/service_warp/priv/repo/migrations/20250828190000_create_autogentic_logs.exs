defmodule ServiceWarp.Repo.Migrations.CreateAutogenticLogs do
  use Ecto.Migration

  def change do
    create table(:autogentic_logs) do
      add :event, :string, null: false
      add :source, :string, null: false, default: "autogentic"
      add :session_id, :string
      add :level, :string
      add :payload, :map

      timestamps(type: :naive_datetime_usec)
    end

    create index(:autogentic_logs, [:event])
    create index(:autogentic_logs, [:inserted_at])
    create index(:autogentic_logs, [:session_id])
  end
end
