alias Maru.Resource

defmodule Resource do
  defstruct path: [],
            parameters: [],
            plugs: [],
            helpers: [],
            version: nil

  defmacro __using__(_) do
    quote do
      import Resource.DSLs
      Module.register_attribute(__MODULE__, :mounted, accumulate: true)
      Module.register_attribute(__MODULE__, :endpoints, accumulate: true)
      Module.register_attribute(__MODULE__, :routes, accumulate: true)

      @resource %Resource{}
      @extend nil
      @router nil
    end
  end

  def before_compile_router(%Macro.Env{module: module} = env) do
    current_routes = Module.get_attribute(module, :routes) |> Enum.reverse()
    mounted_routes = Module.get_attribute(module, :mounted) |> Enum.reverse()
    extend_opts = Module.get_attribute(module, :extend)

    extended =
      Resource.Extend.take_extended(
        current_routes ++ mounted_routes,
        extend_opts
      )

    all_routes = current_routes ++ mounted_routes ++ extended
    Module.put_attribute(module, :all_routes, all_routes)

    routes_quoted =
      quote do
        def __routes__, do: unquote(Macro.escape(all_routes))
      end

    Module.eval_quoted(env, routes_quoted)

    endpoints_quoted =
      Module.get_attribute(module, :endpoints)
      |> Enum.reverse()
      |> Enum.map(&Resource.Helper.dispatch/1)

    Module.eval_quoted(env, endpoints_quoted)
  end
end
