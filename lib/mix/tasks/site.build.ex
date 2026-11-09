defmodule Mix.Tasks.Site.Build do
  @moduledoc "Build the static blog without starting a web server."
  use Mix.Task
  @shortdoc "Build the static blog"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")
    CunweiWong.ContentValidator.validate_sources!()
    CunweiWong.build_all()
    CunweiWong.ContentValidator.validate_output!()
  end
end
