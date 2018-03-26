alias Maru.Builder.PlugRouter
alias Maru.Builder.RETURN

defmodule PlugRouter do
  defmacro __using__(opts) do
    env_config = Application.get_env(:maru, __CALLER__.module)
    versioning = Keyword.get(opts, :versioning) || (env_config || [])[:versioning] || []
    make_plug = Keyword.get(opts, :make_plug, false) or [] != versioning or not is_nil(env_config)

    [
      quote do
        @make_plug unquote(make_plug)
      end,
      if make_plug do
        quote do
          @versioning unquote(versioning)
          @pipe_functions []
          Module.register_attribute(__MODULE__, :plugs_before, accumulate: true)
          import PlugRouter.DSLs, only: [before: 1]
        end
      end
    ]
  end

  @doc false
  def before_compile_router(%Macro.Env{module: module} = env) do
    Module.get_attribute(module, :make_plug) || raise RETURN

    routes = Module.get_attribute(module, :all_routes)
    plugs_before = Module.get_attribute(module, :plugs_before) |> Enum.reverse()
    version_config = Module.get_attribute(module, :versioning)
    version_adapter = Maru.Builder.Versioning.get_adapter(version_config[:using])

    pipeline =
      [
        [{Maru.Plugs.SaveConn, [], true}],
        plugs_before,
        version_adapter.get_version_plug(version_config),
        [{:route, [], true}, {Maru.Plugs.NotFound, [], true}]
      ]
      |> List.flatten()
      |> Enum.reverse()

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    routes_block = make_routes_block(routes, env, version_adapter)
    method_not_allowed_block = make_method_not_allowed_block(routes, version_adapter)

    Module.put_attribute(module, :pipe_functions, [])
    Maru.Builder.Exception.before_build_plug(env)

    func =
      module
      |> Module.get_attribute(:pipe_functions)
      |> PlugRouter.Helper.make_pipe_functions()

    quoted =
      quote do
        unquote(routes_block)
        unquote(method_not_allowed_block)
        defp route(conn, _), do: conn

        def init(_), do: []

        def call(unquote(conn), _) do
          fn ->
            unquote(body)
          end
          |> unquote(func)
          |> apply([])
        end
      end

    Module.eval_quoted(env, quoted)
  rescue
    RETURN -> nil
  end

  defp make_routes_block(routes, %Macro.Env{module: module} = env, version_adapter) do
    Enum.map(routes, fn route ->
      Module.put_attribute(module, :pipe_functions, [])
      Maru.Builder.Exception.before_build_route(route, env)
      PlugRouter.Helper.dispatch(route, env, version_adapter)
    end)
  end

  defp make_method_not_allowed_block(routes, version_adapter) do
    Enum.group_by(routes, fn route -> {route.version, route.path} end)
    |> Enum.map(fn {{version, path}, routes} ->
      unless Enum.any?(routes, fn i -> i.method == :match end) do
        PlugRouter.Helper.dispatch_405(version, path, version_adapter)
      end
    end)
  end
end
