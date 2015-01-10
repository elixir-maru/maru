defmodule Maru.Plugs.Forword do
  alias Plug.Conn

  def init(opts) do
    at = opts |> Keyword.fetch! :at
    to = opts |> Keyword.fetch! :to
    {at, to}
  end

  def call(conn, {at, to}) do
    path = Maru.Router.Path.split at
    case Maru.Router.Path.lstrip(conn.path_info, path) do
      nil         -> conn
      {:ok, rest} ->
        conn
     |> Conn.put_private(:maru_resource_path, rest)
     |> Conn.put_private(:maru_route_path, path)
     |> Maru.Plugs.Prepare.call([])
     |> to.call([])
    end
  end
end
