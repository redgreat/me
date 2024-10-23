defmodule CunweiWong.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    port = 8093

    children = [
      {Bandit, plug: CunweiWong.DevServer, scheme: :http, port: port}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CunweiWong.Supervisor]
    Logger.info("serving dev site at http://localhost:#{port}")
    Supervisor.start_link(children, opts)
  end
end
