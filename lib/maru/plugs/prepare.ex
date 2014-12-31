defmodule Maru.Plugs.Prepare do
  alias Plug.Conn

  def init(_), do: []

  def call(conn, []) do
    conn |> check_path |> check_route_path |> check_param_context
  end

  defp check_path(%Conn{private: %{maru_resource_path: _}}=conn), do: conn
  defp check_path(conn), do: Plug.Conn.put_private(conn, :maru_resource_path, conn.path_info)

  defp check_route_path(%Conn{private: %{maru_route_path: _}}=conn), do: conn
  defp check_route_path(conn), do: Plug.Conn.put_private(conn, :maru_route_path, [])

  defp check_param_context(%Conn{private: %{maru_param_context: _}}=conn), do: conn
  defp check_param_context(conn), do: Plug.Conn.put_private(conn, :maru_param_context, [])
end
