alias Maru.Builder.Plugins.PlugRouter
alias Maru.Builder.Exception.RETURN

defmodule PlugRouter do

  defmacro __using__(opts) do
    env_config = Application.get_env(:maru, __CALLER__.module)
    versioning = Keyword.get(opts, :versioning) || (env_config || [])[:versioning] || []
    make_plug = Keyword.get(opts, :make_plug, false) or ([] != versioning) or not is_nil(env_config)
    [ quote do
        @make_plug unquote(make_plug)
      end,

      if make_plug do
        quote do
          @versioning unquote(versioning)
          Module.register_attribute __MODULE__, :plugs_before, accumulate: true
          import PlugRouter.DSLs, only: [before: 1]
        end
      end
    ]
  end

  @doc false
  def callback_before_compile(%Macro.Env{module: module}=env, routes) do
    Module.get_attribute(module, :make_plug) || raise RETURN

    plugs_before    = Module.get_attribute(module, :plugs_before) |> Enum.reverse
    version_config  = Module.get_attribute(module, :versioning)
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
      |> PlugRouter.Helper.pipe_functions()

    quoted =
      quote do
        unquote(routes_block)
        unquote(method_not_allowed_block)
        defp route(conn, _), do: conn

        def init(_), do: []

        def call(unquote(conn), _) do
          fn ->
            unquote(body)
          end |> unquote(func) |> apply([])
        end
      end

    Module.eval_quoted(env, quoted)
  rescue
    RETURN -> nil
  end

  defp make_routes_block(routes, env, version_adapter) do
    Enum.map(routes, fn route ->
      PlugRouter.Helper.dispatch(route, env, version_adapter)
    end)
  end

  defp make_method_not_allowed_block(routes, version_adapter) do
    Enum.group_by(routes, fn route -> {route.version, route.path} end)
    |> Enum.map(fn {{version, path}, routes} ->
      unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
        PlugRouter.Helper.dispatch_405(version, path, version_adapter)
      end
    end)
  end
end
