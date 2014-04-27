defmodule LazyHelper.Response do
  defmacro __using__(_) do
    quote do
      import Plug.Conn
      import unquote(__MODULE__)
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
      var!(conn).req_headers
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


  defmacro json(reply) do
    quote do
      content_type "application/json"
      var!(conn) |> send_resp(200, unquote(reply) |> JSON.encode!)
    end
  end


  defmacro html(reply) do
    quote do
      content_type "text/html"
      var!(conn) |> send_resp(200, unquote(reply))
    end
  end


  defmacro text(reply) do
    quote do
      content_type("text/plain")
      var!(conn) |> send_resp(200, unquote(reply))
    end
  end
end