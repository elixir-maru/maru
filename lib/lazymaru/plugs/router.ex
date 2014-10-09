defmodule Lazymaru.Plugs.Router do
  alias Lazymaru.Router.Resource
  alias Plug.Conn

  def init(opts) do
    router = opts |> Keyword.fetch! :router
    'Elixir.' ++ _ = Atom.to_char_list router
    %Resource{path: path, param_context: param_context} = opts |> Keyword.get :resource, %Resource{}
    {router, path, param_context}
  end


  def call(conn_orig, {router, path, param_context}) do
    %{ lazymaru_resource_path: lazymaru_resource_path,
       lazymaru_route_path:    lazymaru_route_path,
       lazymaru_param_context: lazymaru_param_context
     } = conn_orig.private
    case Lazymaru.Router.Path.lstrip(lazymaru_resource_path, path) do
      nil         -> conn_orig
      {:ok, rest} ->
        conn_orig
     |> Conn.put_private(:lazymaru_resource_path, rest)
     |> Conn.put_private(:lazymaru_route_path, lazymaru_route_path ++ path)
     |> Conn.put_private(:lazymaru_param_context, lazymaru_param_context ++ param_context)
     |> router.call([])
     |> case do
          %Conn{halted: true} = conn -> conn
          %Conn{}                    -> conn_orig
        end
    end
  end

end
