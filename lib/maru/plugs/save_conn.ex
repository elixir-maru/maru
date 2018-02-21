defmodule Maru.Plugs.SaveConn do
  @moduledoc """
  This module is a plug, save current conn to process dict.
  """

  @doc false
  def init(_), do: nil

  @doc false
  def call(conn, _) do
    Maru.Response.put_maru_conn(conn)
    conn
  end
end
