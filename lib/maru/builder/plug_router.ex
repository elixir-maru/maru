defmodule Maru.Builder.PlugRouter do

  @doc false
  def __before_compile__(%Macro.Env{module: module}=env, routes) do
    plugs_before    = Module.get_attribute(module, :plugs_before) |> Enum.reverse
    version_config  = (Application.get_env(:maru, module) || [])[:versioning] || []
    version_adapter = Maru.Builder.Versioning.get_adapter(version_config[:using])

    pipeline = [
      [{Maru.Plugs.SaveConn, [], true}],
      plugs_before,
      version_adapter.get_version_plug(version_config),
      [ {:route, [], true},
        {Maru.Plugs.NotFound, [], true},
      ],
    ] |> Enum.concat |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    routes_block = make_routes_block(routes, env, version_adapter)
    method_not_allowed_block = make_method_not_allowed_block(routes, version_adapter)

    func =
      env
      |> Maru.Builder.Plugins.Exception.callback_plug_router()
      |> Maru.Builder.Route.pipe_functions()

    [ quote do
        unquote(routes_block)
        unquote(method_not_allowed_block)
        defp route(conn, _), do: conn

        def init(_), do: []
      end,

      quote do
        def call(unquote(conn), _) do
          fn ->
            unquote(body)
          end |> unquote(func) |> apply([])
        end
      end
    ]
  end

  defp make_routes_block(routes, env, version_adapter) do
    Enum.map(routes, fn route ->
      Maru.Builder.Route.dispatch(route, env, version_adapter)
    end)
  end

  defp make_method_not_allowed_block(routes, version_adapter) do
    Enum.group_by(routes, fn route -> {route.version, route.path} end)
    |> Enum.map(fn {{version, path}, routes} ->
      unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
        Maru.Builder.Route.dispatch_405(version, path, version_adapter)
      end
    end)
  end
end
