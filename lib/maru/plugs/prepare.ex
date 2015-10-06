defmodule Maru.Plugs.Prepare do
  @moduledoc """
  This module is a plug, prepare private variable.
  """

  alias Plug.Conn

  @doc false
  def init(_), do: []

  @doc false
  def call(conn, []) do
    conn |> check_path |> check_route_path |> check_param_context |> check_version |> check_body
  end

  defp check_path(%Conn{private: %{maru_resource_path: _}}=conn), do: conn
  defp check_path(conn), do: Conn.put_private(conn, :maru_resource_path, conn.path_info)

  defp check_route_path(%Conn{private: %{maru_route_path: _}}=conn), do: conn
  defp check_route_path(conn), do: Conn.put_private(conn, :maru_route_path, [])

  defp check_param_context(%Conn{private: %{maru_param_context: _}}=conn), do: conn
  defp check_param_context(conn), do: Conn.put_private(conn, :maru_param_context, [])

  defp check_version(%Conn{private: %{maru_version: _}}=conn), do: conn
  defp check_version(conn), do: Conn.put_private(conn, :maru_version, nil)

  defp check_body(%Conn{private: %{maru_body: _}}=conn), do: conn
  defp check_body(conn), do: Conn.put_private(conn, :maru_body, nil)
end
