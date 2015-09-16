defmodule Maru.Helpers.Response do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro params do
    quote do
      var!(conn).private[:maru_params] || %{}
    end
  end


  defmacro assigns do
    quote do
      var!(conn).assigns
    end
  end

  defmacro assign(key, value) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.assign(unquote(key), unquote(value))
    end
  end


  defmacro headers do
    quote do
      var!(conn).req_headers |> Enum.into %{}
    end
  end

  defmacro header(key, nil) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.delete_resp_header(unquote(key))
    end
  end

  defmacro header(key, value) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_header(unquote(key), unquote(value))
    end
  end


  defmacro content_type(value) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_content_type(unquote(value))
    end
  end


  defmacro status(value) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_status(unquote(value))
    end
  end


  defmacro present(payload, opts) do
    quote do
      var!(conn) = var!(conn) |> unquote(__MODULE__).put_present(unquote(payload), unquote(opts))
    end
  end

  defmacro present(key, payload, opts) do
    quote do
      var!(conn) = var!(conn) |> unquote(__MODULE__).put_present(unquote(key), unquote(payload), unquote(opts))
    end
  end

  def put_present(conn, payload, opts) do
    value = get_present_value(payload, opts)
    conn |> Plug.Conn.put_private(:maru_present, value)
  end

  def put_present(conn, key, payload, opts) do
    present = conn.private[:maru_present] || %{}
    value = present |> put_in([key], get_present_value(payload, opts))
    conn |> Plug.Conn.put_private(:maru_present, value)
  end

  defp get_present_value(payload, opts) do
    opts |> Enum.into(%{}) |> Dict.pop(:with) |> case do
      {nil, _} ->
        payload
      {entity_klass, opts} ->
        entity_klass.serialize(payload, opts)
    end
  end


  defmacro redirect(url) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_header("location", unquote(url))
   |> Plug.Conn.put_status(302)
   |> Plug.Conn.halt
    end
  end

  defmacro redirect(url, permanent: true) do
    quote do
      var!(conn) = var!(conn)
   |> Plug.Conn.put_resp_header("location", unquote(url))
   |> Plug.Conn.put_status(301)
   |> Plug.Conn.halt
    end
  end
end
