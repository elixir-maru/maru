defmodule Maru.Helpers.Response do
  @moduledoc """
  This module is a wrapper for request and response of maru.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      import Plug.Conn
    end
  end

  @doc """
  Get params.
  """
  def get_maru_params(conn) do
    conn.private[:maru_params]
  end

  @doc """
  Make response by url redirect.
  """
  def redirect(%Plug.Conn{} = conn, url, opts \\ []) do
    code = (opts[:permanent] && 301) || 302

    conn
    |> Plug.Conn.put_resp_header("location", url)
    |> Plug.Conn.send_resp(code, "")
    |> Plug.Conn.halt()
  end

  @doc """
  Make json format response.
  """
  def json(%Plug.Conn{} = conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(conn.status || 200, Poison.encode_to_iodata!(data))
    |> Plug.Conn.halt()
  end

  @doc """
  Make html format response.
  """
  def html(%Plug.Conn{} = conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(conn.status || 200, to_string(data))
    |> Plug.Conn.halt()
  end

  @doc """
  Make text format response.
  """
  def text(%Plug.Conn{} = conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(conn.status || 200, to_string(data))
    |> Plug.Conn.halt()
  end

  @doc """
  Put conn to process dict.
  """
  def put_maru_conn(conn) do
    Process.put(:maru_conn, conn)
  end

  @doc """
  Get conn from process dict.
  """
  def get_maru_conn do
    Process.get(:maru_conn)
  end
end
