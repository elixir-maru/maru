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


  defmacro json(reply, code \\ 200) do
    IO.write :stderr, "warning: json/1 and json/2 is deprecated, in faver of returning Map directly.\n"
    quote do
      content_type "application/json"
      var!(conn) |> Plug.Conn.send_resp(unquote(code), unquote(reply) |> Poison.encode!) |> Plug.Conn.halt
    end
  end


  defmacro html(reply, code \\ 200) do
    IO.write :stderr, "warning: html/1 and html/2 is deprecated, in faver of setting content_type and returning String directly.\n"
    quote do
      content_type "text/html"
      var!(conn) |> Plug.Conn.send_resp(unquote(code), unquote(reply)) |> Plug.Conn.halt
    end
  end


  defmacro text(reply, code \\ 200) do
    IO.write :stderr, "warning: test/1 and text/2 is deprecated, in faver of returning String directly.\n"
    quote do
      content_type "text/plain"
      var!(conn) |> Plug.Conn.send_resp(unquote(code), unquote(reply)) |> Plug.Conn.halt
    end
  end
end
