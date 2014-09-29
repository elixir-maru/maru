defmodule Lazymaru.Plugs.NotFound do
  def init(opts), do: opts
  def call(conn, _) do
    Lazymaru.Exceptions.NotFound |> raise [method: conn.method, path_info: conn.path_info]
  end
end
