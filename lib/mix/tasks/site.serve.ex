defmodule Mix.Tasks.Site.Serve do
  @moduledoc "Build and preview the blog on localhost:8093."
  use Mix.Task
  @shortdoc "Preview the blog locally"

  @impl true
  def run(_args) do
    Mix.Task.run("site.build")
    {:ok, _pid} = Bandit.start_link(plug: CunweiWong.DevServer, ip: {127, 0, 0, 1}, port: 8093)
    Mix.shell().info("http://localhost:8093")
    Process.sleep(:infinity)
  end
end
