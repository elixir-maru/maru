defmodule Lazymaru.Handler do
  import Plug.Connection

  def call(conn, mod) do
    method = conn.method |> String.downcase |> binary_to_atom
    try do
      mod.service(method, conn.path_info, conn)
    rescue
      FunctionClauseError ->
        conn |> put_resp_content_type("text/plain") |> send_resp(404, "Not Found")
    end
  end
end