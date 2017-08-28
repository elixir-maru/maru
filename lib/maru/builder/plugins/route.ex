alias Maru.Builder.Plugins.Route

defmodule Route do
  defstruct [
    method:     nil,
    path:       [],
    version:    nil,
    parameters: [],
    helpers:    [],
    plugs:      [],
    module:     nil,
    func_id:    nil,
  ]
  ++ Maru.Builder.Plugins.Exception.route_struct()
  ++ Maru.Builder.Plugins.Description.route_struct()


  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :routes,  accumulate: true
      @func_id 0

      use Route.Mount
      use Route.Endpoint
    end
  end

  def callback_build_method(%Macro.Env{module: module}=env) do
    func_id = Module.get_attribute(module, :func_id)
    Module.put_attribute(module, :func_id, func_id + 1)

    context = Module.get_attribute(module, :context)
    Module.put_attribute(module, :context, Map.put(context, :func_id, func_id))

    route =
      context
      |> Map.take([:method, :version, :path, :parameters, :helpers, :plugs])
      |> Map.merge(%{module: module, func_id: func_id})
    Module.put_attribute(module, :route, struct(Route, route))

    Maru.Builder.Plugins.Description.callback_build_route(env)
    route = Module.get_attribute(module, :route)
    Module.put_attribute(module, :routes, route)

    Route.Endpoint.callback_build_method(env)
  end

  def callback_before_compile(%Macro.Env{module: module}=env) do
    current_routes = Module.get_attribute(module, :routes)  |> Enum.reverse
    mounted_routes = Module.get_attribute(module, :mounted) |> Enum.reverse
    extend_opts    = Module.get_attribute(module, :extend)
    extended       = Route.Extend.take_extended(
      current_routes ++ mounted_routes, extend_opts
    )
    all_routes     = current_routes ++ mounted_routes ++ extended
    Module.put_attribute(module, :all_routes, all_routes)

    quoted = quote do
      def __routes__, do: unquote(Macro.escape(all_routes))
    end
    Module.eval_quoted(env, quoted)

    Route.Endpoint.callback_before_compile(env)
  end
end
