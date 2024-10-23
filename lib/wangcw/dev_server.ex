defmodule CunweiWong.DevServer do
  @moduledoc false
  use Plug.Router
  CunweiWong.build_all()

  def __mix_recompile__?, do: true

  plug(Plug.Logger, log: :info)
  plug(Plug.Static, at: "/", from: "output")
  plug(:match)
  plug(:dispatch)

  get "/*path" do
    decoded_path = URI.decode(conn.path_info |> Enum.join("/"))
    full_path = Path.join([File.cwd!(), "output", decoded_path, "index.html"])

    if File.exists?(full_path) do
      send_file(conn, 200, full_path)
    else
      not_found_path = Path.join([File.cwd!(), "output", "404.html"])
      send_file(conn, 404, not_found_path)
    end
  end
end
