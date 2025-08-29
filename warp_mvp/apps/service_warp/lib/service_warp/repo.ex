defmodule ServiceWarp.Repo do
  use Ecto.Repo,
    otp_app: :service_warp,
    adapter: Ecto.Adapters.Postgres
end
