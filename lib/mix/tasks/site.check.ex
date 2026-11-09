defmodule Mix.Tasks.Site.Check do
  @moduledoc "Check all Markdown sources before building the static site."
  use Mix.Task
  @shortdoc "Check Markdown files and their local assets"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")
    CunweiWong.ContentValidator.validate_sources!()
    Mix.shell().info("Markdown source checks passed.")
  end
end
