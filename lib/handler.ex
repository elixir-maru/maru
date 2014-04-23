defmodule Lazymaru.Handler do
  import Plug.Conn

  def init(option) do
    option
  end


  def call(conn, mod) do
    method = conn.method |> String.downcase |> binary_to_atom
    try do
      mod.service(method, conn.path_info, conn)
    rescue
      e in [LazyException.InvalidFormatter] ->
        IO.inspect e
        conn |> put_resp_content_type("text/plain") |> send_resp(500, "Server Error")
      FunctionClauseError ->
        conn |> put_resp_content_type("text/plain") |> send_resp(404, "Not Found")
    end
  end
end