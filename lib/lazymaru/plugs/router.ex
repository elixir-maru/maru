defmodule Lazymaru.Plugs.Router do
  alias Lazymaru.Router.Resource
  alias Plug.Conn

  def init(opts) do
    router = opts |> Keyword.fetch! :router
    %Resource{path: path, params: params} = opts |> Keyword.get :resource, %Resource{}
    {router, path, params}
  end


  def call(conn, {router, path, params}) do
    case Lazymaru.Router.Path.pick_params(conn, path, params) do
      nil   -> conn
      conn1 ->
        case Atom.to_char_list(router) do
          'Elixir.' ++ _ ->
            router.call(conn1, [])
          _ ->
            router.(conn1, [])
        end
      |> case do
           %Conn{halted: true} = conn2 -> conn2
           %Conn{}                     -> conn
         end
    end
  end

end
