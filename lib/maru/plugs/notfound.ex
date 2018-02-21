defmodule Maru.Plugs.NotFound do
  @moduledoc """
  This module is a plug, match all path and raise `Maru.Exceptions.NotFound`.
  """

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _) do
    Maru.Exceptions.NotFound |> raise(method: conn.method, path_info: conn.path_info)
  end
end
