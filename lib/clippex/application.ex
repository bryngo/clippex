defmodule Clippex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClippexWeb.Telemetry,
      Clippex.Repo,
      {DNSCluster, query: Application.get_env(:clippex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Clippex.PubSub},
      # Start a worker by calling: Clippex.Worker.start_link(arg)
      # {Clippex.Worker, arg},
      Clippex.Workers.StitchWorker,
      # Start to serve requests, typically the last entry
      ClippexWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Clippex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClippexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
