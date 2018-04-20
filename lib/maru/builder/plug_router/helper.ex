alias Maru.Builder.PlugRouter

defmodule PlugRouter.Helper do
  @doc """
  Generate general route defined by user within method block.
  """
  def dispatch(route, %Macro.Env{module: module} = env, adapter) do
    pipeline =
      [
        adapter.put_version_plug(route.version),
        [{Maru.Plugs.SaveConn, [], true}],
        Enum.map(route.plugs, fn p ->
          {p.plug, p.options, p.guards}
        end)
      ]
      |> Enum.concat()
      |> Enum.reverse()

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    path_params =
      quote do
        PlugRouter.Runtime.parse_path_params(
          var!(conn).path_info,
          unquote(adapter.path_for_params(route.path, route.version))
        )
      end

    parameters_runtime = route.parameters |> Enum.map(fn p -> p.runtime end)

    parser_block =
      quote do
        PlugRouter.Runtime.parse_params(
          unquote(parameters_runtime),
          %{},
          var!(conn).params
        )
      end

    params_block =
      quote do
        var!(conn) = Map.put(var!(conn), :path_params, unquote(path_params))

        var!(conn) =
          Map.put(var!(conn), :params, Map.merge(var!(conn).params, var!(conn).path_params))

        var!(conn) = Plug.Conn.put_private(var!(conn), :maru_params, unquote(parser_block))
        Maru.Response.put_maru_conn(var!(conn))
      end

    func =
      module
      |> Module.get_attribute(:pipe_functions)
      |> make_pipe_functions()

    quote do
      defp route(
             unquote(adapter.conn_for_match(route.method, route.version, route.path)) =
               unquote(conn),
             []
           ) do
        fn ->
          case unquote(body) do
            %Plug.Conn{halted: true} = conn ->
              conn

            %Plug.Conn{} = var!(conn) ->
              unquote(params_block)
              unquote(route.module).endpoint(var!(conn), unquote(route.func_id))
          end
        end
        |> unquote(func)
        |> apply([])
      end
    end
  end

  @doc """
  Generate MethodNotAllowed route for all path without `match` method.
  """
  def dispatch_405(version, path, adapter) do
    quote do
      defp route(unquote(adapter.conn_for_match(:match, version, path)) = var!(conn), []) do
        raise Maru.Exceptions.MethodNotAllowed,
          method: var!(conn).method,
          request_path: var!(conn).request_path
      end
    end
  end

  def make_pipe_functions(mf_list) do
    quote do
      (fn func ->
         Enum.reduce(unquote(mf_list), func, fn {m, f}, func ->
           apply(m, f, [func])
         end)
       end).()
    end
  end
end
