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
      use Route.Mount
    end
  end

  def callback_build_method(%Macro.Env{module: module}=env) do
    route =
      Module.get_attribute(module, :context)
      |> Map.take([:method, :version, :path, :parameters, :helpers, :plugs, :func_id])
      |> Map.put(:module, module)
    Module.put_attribute(module, :route, struct(Route, route))

    Maru.Builder.Plugins.Description.callback_build_route(env)
    route = Module.get_attribute(module, :route)
    Module.put_attribute(module, :routes, route)
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
  end
end
