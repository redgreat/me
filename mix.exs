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
      {:nimble_publisher, "~> 1.1.0"},
      {:earmark, "~> 1.4.48"},
      {:makeup_elixir, "~> 1.0.1"},
      {:makeup_html, "~> 0.2.0"},
      {:phoenix_live_view, "~> 1.1.16"},
      {:xml_builder, "~> 2.4.0"},
      {:yaml_elixir, "~> 2.12.0"},
      {:html_sanitize_ex, "~> 1.5.0"},
      {:tailwind, "~> 0.4.1"},
      {:bandit, "~> 1.10.3"},
      {:credo, "~> 1.7.8"}
    ]
  end
end
