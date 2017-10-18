defmodule Maru.Builder.Route do
  @moduledoc """
  Generate routes of maru router.
  """

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

    path_params = quote do
      Maru.Builder.Path.parse_params(
        var!(conn).path_info,
        unquote(adapter.path_for_params(route.path, route.version))
      )
    end

    parameters_runtime = route.parameters |> Enum.map(fn p -> p.runtime end)
    parser_block = quote do
      Maru.Runtime.parse_params(
        unquote(parameters_runtime), %{}, var!(conn).params
      )
    end

    params_block = quote do
      var!(conn) = Map.put(var!(conn), :path_params, unquote(path_params))
      var!(conn) = Map.put(var!(conn), :params, Map.merge(var!(conn).params, var!(conn).path_params))
      var!(conn) = Plug.Conn.put_private(var!(conn), :maru_params, unquote(parser_block))
     Maru.Helpers.Response.put_maru_conn(var!(conn))
    end

    func = exception_function(route.mount_link)
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
  def dispatch_405(version, path, mount_link, adapter) do
    method = Macro.var(:_, nil)
    func = exception_function(mount_link)

    quote do
      defp route(unquote(
        adapter.conn_for_match(method, version, path)
      )=var!(conn), []) do
        fn ->
          Maru.Exceptions.MethodNotAllowed
          |> raise([method: var!(conn).method, request_path: var!(conn).request_path])
        end |> unquote(func) |> apply([])
      end
    end
  end

  defp exception_function(mount_link) do
    exception_modules =
      Enum.filter(mount_link, fn module ->
        if Module.open?(module) do
          Module.get_attribute(module, :exceptions) != []
        else
          {:__error_handler__, 1} in module.__info__(:functions)
        end
      end)

    quote do
      fn func ->
        Enum.reduce(
          unquote(exception_modules),
          func,
          fn module, func ->
            module.__error_handler__(func)
          end
        )
      end.()
    end
  end

end
