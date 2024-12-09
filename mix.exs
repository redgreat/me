defmodule CunweiWong.MixProject do
  use Mix.Project

  def project do
    [
      app: :wangcw,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:nimble_publisher, "~> 1.1.0"},
      {:makeup_elixir, "~> 0.16.2"},
      {:makeup_js, "~> 0.1.0"},
      {:makeup_html, "~> 0.1.1"},
      {:phoenix_live_view, "~> 1.0.0"},
      {:xml_builder, "~> 2.3.0"},
      {:yaml_elixir, "~> 2.11.0"},
      {:html_sanitize_ex, "~> 1.4.3"},
      {:tailwind, "~> 0.2.4"},
      {:bandit, "~> 1.5.7"},
      {:exsync, "~> 0.4.1"},
      {:credo, "~> 1.7.8"}
    ]
  end
end
