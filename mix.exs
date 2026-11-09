defmodule CunweiWong.MixProject do
  use Mix.Project

  def project do
    [
      app: :wangcw,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CunweiWong.Application, []}
    ]
  end

  defp deps do
    [
      {:nimble_publisher, "~> 2.2.0"},
      {:makeup_elixir, "~> 1.0.1"},
      {:makeup_html, "~> 1.0.0"},
      {:phoenix_live_view, "~> 1.2.3"},
      {:tailwind, "~> 0.5.1"},
      {:bandit, "~> 1.14.1"},
      {:credo, "~> 1.7.8"}
    ]
  end
end
