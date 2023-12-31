defmodule Vtick.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VtickWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:vtick, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Vtick.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Vtick.Finch},
      # Start a worker by calling: Vtick.Worker.start_link(arg)
      # {Vtick.Worker, arg},
      {Vtick.TickerState, name: Vtick.TickerState},
      {Vtick.TickerClient, name: Vtick.TickerClient},
      {Vtick.MatchSelector, name: Vtick.MatchSelector},
      {Vtick.PlayerSelector, name: Vtick.PlayerSelector},
      # Start to serve requests, typically the last entry
      VtickWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vtick.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VtickWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
