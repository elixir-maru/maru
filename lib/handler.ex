defmodule Lazymaru.Handler do
  @behaviour :cowboy_http_handler
  @connection Plug.Adapters.Cowboy.Conn

  def init({transport, :http}, req, %{mod: mod, hooks: hooks}) when transport in [:tcp, :ssl] do
    conn = @connection.conn(req, transport)
    app = fn (conn) ->
      method = conn.method |> String.downcase |> binary_to_atom
      path = conn.path_info
      mod.service(method, path, conn)
    end
    case reduce(hooks, conn, app) do
      %Plug.Conn{adapter: {@connection, req}} ->
        {:ok, req, nil}
      other ->
        raise "Cowboy adapter Error, got: #{inspect other}"
    end
  end

  def reduce([], conn, app), do: app.(conn)
  def reduce([h|t], conn, app) do
    functions = h.__info__(:functions)
    if {:before, 1} in functions do
      conn = h.before(conn)
    end
    if {:call, 2} in functions do
      conn = h.call(conn, app)
      app = fn conn -> conn end
    end
    if {:finish, 1} in functions do
      conn = h.finish(conn)
    end
    reduce(t, conn, app)
  end

  def handle(req, nil) do
    {:ok, req, nil}
  end

  def terminate(_reason, _req, nil) do
    :ok
  end
end
