defmodule LazyHelper.Response do
  defmacro __using__(_) do
    quote do
      import Plug.Conn
      import unquote(__MODULE__)
    end
  end

  defmacro json(reply) do
    quote do
      var!(conn)
   |> put_resp_content_type("application/json")
   |> send_resp(200, unquote(reply) |> JSON.encode!)
    end
  end


  defmacro html(reply) do
    quote do
      var!(conn)
   |> put_resp_content_type("text/html")
   |> send_resp(200, unquote(reply))
    end
  end


  defmacro text(reply) do
    quote do
      var!(conn)
   |> put_resp_content_type("text/plain")
   |> send_resp(200, unquote(reply))
    end
  end
end