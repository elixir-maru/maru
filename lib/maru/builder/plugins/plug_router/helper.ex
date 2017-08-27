alias Maru.Builder.Plugins.PlugRouter

defmodule PlugRouter.Helper do

  @doc """
  Generate general route defined by user within method block.
  """
  def dispatch(route, env, adapter) do
    pipeline = [
      adapter.put_version_plug(route.version),
      [{Maru.Plugs.SaveConn, [], true}],
      Enum.map(route.plugs, fn p ->
        {p.plug, p.options, p.guards}
      end)
    ] |> Enum.concat |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    params = quote do
      Map.merge(
        var!(conn).params,
        Maru.Builder.Path.parse_params(
          var!(conn).path_info,
          unquote(adapter.path_for_params(route.path, route.version))
        )
      )
    end

    parameters_runtime = route.parameters |> Enum.map(fn p -> p.runtime end)
    parser_block = quote do
      Maru.Runtime.parse_params(
        unquote(parameters_runtime), %{}, unquote(params)
      )
    end

    params_block = quote do
      var!(conn) =
        Plug.Conn.put_private(
          var!(conn),
          :maru_params,
          unquote(parser_block)
        )
      Maru.Helpers.Response.put_maru_conn(var!(conn))
    end

    func =
      route
      |> Maru.Builder.Plugins.Exception.callback_route(env)
      |> pipe_functions()

    quote do
      defp route(unquote(
        adapter.conn_for_match(route.method, route.version, route.path)
      )=unquote(conn), []) do
        fn ->
          case unquote(body) do
            %Plug.Conn{halted: true} = conn ->
              conn
            %Plug.Conn{} = var!(conn) ->
              unquote(params_block)
              unquote(route.module).endpoint(var!(conn), unquote(route.func_id))
          end
        end |> unquote(func) |> apply([])
      end
    end

  end

  @doc """
  Generate MethodNotAllowed route for all path without `match` method.
  """
  def dispatch_405(version, path, adapter) do
    method = Macro.var(:_, nil)

    quote do
      defp route(unquote(
        adapter.conn_for_match(method, version, path)
      )=var!(conn), []) do
          raise Maru.Exceptions.MethodNotAllowed, [method: var!(conn).method, request_path: var!(conn).request_path]
      end
    end
  end

  def pipe_functions(mfs) do
    quote do
      fn func ->
        Enum.reduce(
          unquote(mfs),
          func,
          fn {m, f}, func ->
            apply(m, f, [func])
          end
        )
      end.()
    end
  end

end
