defmodule CunweiWong.DevServer do
  @moduledoc false
  use Plug.Router

  plug(Plug.Logger, log: :info)
  plug(Plug.Static, at: "/", from: "output")
  plug(:match)
  plug(:dispatch)

  get "/*path" do
    root = Path.expand("output")
    segments = Enum.map(conn.path_info, &URI.decode/1)

    safe? =
      Enum.all?(
        segments,
        &(&1 not in [".", ".."] and not String.contains?(&1, ["/", "\\", ":", <<0>>]))
      )

    full_path = Path.join([root | segments] ++ ["index.html"])

    if safe? and File.regular?(full_path) do
      send_file(conn, 200, full_path)
    else
      send_file(conn, 404, Path.join(root, "404.html"))
    end
  end
end
