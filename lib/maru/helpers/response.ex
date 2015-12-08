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
  defmacro params do
    quote do
      var!(conn).private[:maru_params] || %{}
    end
  end


  @doc """
  Get assigns.
  """
  defmacro assigns do
    IO.puts :stderr, "assigns is deprecated in favor of conn.assigns."
    quote do
      var!(conn).assigns
    end
  end


  @doc """
  Set assign.
  """
  defmacro assign(key, value) do
    IO.puts :stderr, "assign/2 is deprecated in favor of assign/3."
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.assign(unquote(key), unquote(value))
    end
  end


  @doc """
  Get headers.
  """
  defmacro headers do
    IO.puts :stderr, "headers is deprecated in favor of conn.req_headers."
    quote do
      var!(conn).req_headers |> Enum.into %{}
    end
  end


  @doc """
  Set or delete header.
  """
  defmacro header(key, nil) do
    IO.puts :stderr, "header/2 is deprecated in favor of put_resp_header/3, update_resp_header/3, delete_resp_header/3, merge_resp_headers/3."
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.delete_resp_header(unquote(key))
    end
  end

  defmacro header(key, value) do
    IO.puts :stderr, "header/2 is deprecated in favor of put_resp_header/3, update_resp_header/3, delete_resp_header/3, merge_resp_headers/3."
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_header(unquote(key), unquote(value))
    end
  end


  @doc false
  defmacro fetch_req_body do
    IO.puts :stderr, "fetch_req_body/1 is deprecated. Access request details through conn"
    quote do
      {state, body, _} = var!(conn) |> Plug.Conn.read_body
      var!(conn) = var!(conn) |> Plug.Conn.put_private(:maru_body, {state, body})
    end
  end


  @doc false
  defmacro req_body do
    IO.puts :stderr, "req_body/1 is deprecated."
    quote do
      case var!(conn).private.maru_body do
        nil -> {:error, :unfetched}
        body -> body
      end
    end
  end


  @doc """
  Set content_type.
  """
  defmacro content_type(value) do
    IO.puts :stderr, "content_type/1 is deprecated in favor of put_resp_content_type/2"
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_content_type(unquote(value))
    end
  end


  @doc """
  Set status.
  """
  defmacro status(value) do
    IO.puts :stderr, "status/1 is deprecated in favor of put_status/2"
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_status(unquote(value))
    end
  end


  @doc """
  Make response by (maru_entity)[https://hex.pm/packages/maru_entity] or key-value pairs.
  """
  defmacro present(payload, opts) do
    IO.puts :stderr, "present/2 is deprecated in favor of put_present/3"
    quote do
      var!(conn) = var!(conn) |> unquote(__MODULE__).put_present(unquote(payload), unquote(opts))
    end
  end

  defmacro present(key, payload, opts) do
    IO.puts :stderr, "present/3 is deprecated in favor of put_present/4"
    quote do
      var!(conn) = var!(conn) |> unquote(__MODULE__).put_present(unquote(key), unquote(payload), unquote(opts))
    end
  end


  @doc """
  Make response by url redirect.
  """
  def redirect(%Plug.Conn{}=conn, url, opts \\ []) do
    code = opts[:permanent] && 301 || 302
    conn
 |> Plug.Conn.put_resp_header("location", url)
 |> Plug.Conn.put_status(code)
 |> Plug.Conn.halt
  end


  def json(%Plug.Conn{}=conn, data) do
    conn
 |> Plug.Conn.put_resp_content_type("application/json")
 |> Plug.Conn.send_resp(conn.status || 200, Poison.encode_to_iodata!(data))
 |> Plug.Conn.halt
  end

  def html(%Plug.Conn{}=conn, data) do
    conn
 |> Plug.Conn.put_resp_content_type("text/html")
 |> Plug.Conn.send_resp(conn.status || 200, to_string(data))
 |> Plug.Conn.halt
  end

  def text(%Plug.Conn{}=conn, data) do
    conn
 |> Plug.Conn.put_resp_content_type("text/plain")
 |> Plug.Conn.send_resp(conn.status || 200, to_string(data))
 |> Plug.Conn.halt
  end

end
