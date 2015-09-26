defmodule Maru.Plugs.Router do
  @moduledoc """
  This module is a plug, route mounted routers.
  """

  alias Maru.Router.Resource
  alias Plug.Conn

  @doc false
  def init(opts) do
    router = opts |> Keyword.fetch! :router
    'Elixir.' ++ _ = Atom.to_char_list router
    version = opts |> Keyword.fetch! :version
    %Resource{path: path, param_context: param_context} = opts |> Keyword.get :resource, %Resource{}
    {router, path, version, param_context}
  end

  @doc false
  def call(%Conn{private: %{maru_version: v1}}=conn_orig, {router, path, v2, param_context})
  when is_nil(v2) or v1 == v2 do
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

  def call(conn, _) do
    conn
  end
end
