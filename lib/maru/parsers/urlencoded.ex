defmodule Maru.Parsers.URLENCODED do
  @moduledoc """
  Fork from Plug.Parsers.URLENCODED, version: plug v1.0.2
  """

  @behaviour Plug.Parsers
  alias Plug.Conn

  def parse(conn, "application", "x-www-form-urlencoded", _headers, opts) do
    case conn.private.maru_body do
      nil -> Conn.read_body(conn, opts)
      {:ok, body} -> {:ok, body, conn}
      {:more, body} -> {:more, body, conn}
    end
 |> case do
      {:ok, body, conn} ->
        Plug.Conn.Utils.validate_utf8!(body, "urlencoded body")
        {:ok, Plug.Conn.Query.decode(body), conn}
      {:more, _data, conn} ->
        {:error, :too_large, conn}
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
