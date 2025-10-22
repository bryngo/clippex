defmodule Clippex.Repo do
  use Ecto.Repo,
    otp_app: :clippex,
    adapter: Ecto.Adapters.Postgres
end
