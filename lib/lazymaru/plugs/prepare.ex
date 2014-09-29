defmodule Lazymaru.Plugs.Prepare do
  alias Plug.Conn

  def init(_), do: []

  def call(conn, []) do
    conn |> check_path |> check_params
  end

  defp check_path(%Conn{private: %{lazymaru_path: _}}=conn), do: conn
  defp check_path(conn), do: Plug.Conn.put_private(conn, :lazymaru_path, conn.path_info)

  defp check_params(%Conn{private: %{lazymaru_params: _}}=conn), do: conn
  defp check_params(conn), do: Plug.Conn.put_private(conn, :lazymaru_params, %{})
end
