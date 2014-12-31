defmodule Maru.Plugs.Router do
  alias Maru.Router.Resource
  alias Plug.Conn

  def init(opts) do
    router = opts |> Keyword.fetch! :router
    'Elixir.' ++ _ = Atom.to_char_list router
    %Resource{path: path, param_context: param_context} = opts |> Keyword.get :resource, %Resource{}
    {router, path, param_context}
  end


  def call(conn_orig, {router, path, param_context}) do
    %{ maru_resource_path: maru_resource_path,
       maru_route_path:    maru_route_path,
       maru_param_context: maru_param_context
     } = conn_orig.private
    case Maru.Router.Path.lstrip(maru_resource_path, path) do
      nil         -> conn_orig
      {:ok, rest} ->
        conn_orig
     |> Conn.put_private(:maru_resource_path, rest)
     |> Conn.put_private(:maru_route_path, maru_route_path ++ path)
     |> Conn.put_private(:maru_param_context, maru_param_context ++ param_context)
     |> router.call([])
     |> case do
          %Conn{halted: true} = conn -> conn
          %Conn{}                    -> conn_orig
        end
    end
  end

end
