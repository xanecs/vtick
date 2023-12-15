defmodule Vtick.Repo do
  use Ecto.Repo,
    otp_app: :vtick,
    adapter: Ecto.Adapters.Postgres
end
