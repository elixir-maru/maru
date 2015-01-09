defmodule Maru.Plugs.Version do
  alias Plug.Conn

  def init(opts) do
    opts |> Keyword.pop :using, :path # [:path, :param, :accept_version_header, :header]
  end

  def call(conn, {:path, _opts}) do
    case conn.private do
      %{ maru_resource_path: [version | rest],
         maru_route_path:    route_path
       } -> conn
         |> Conn.put_private(:maru_resource_path, rest)
         |> Conn.put_private(:maru_route_path, [version | route_path])
         |> Conn.put_private(:maru_version, version)
      _  -> conn
    end
  end

  def call(conn, {:param, opts}) do
    case opts |> Keyword.get(:parameter, :apiver) do
      nil ->
        conn
      key ->
        version = conn.params[to_string(key)]
        conn |> Conn.put_private(:maru_version, version)
    end
  end

  def call(conn, {:accept_version_header, _opts}) do
    case Conn.get_req_header(conn, "accept-version") do
      [version] -> conn |> Conn.put_private(:maru_version, version)
      _         -> conn
    end
  end
end
