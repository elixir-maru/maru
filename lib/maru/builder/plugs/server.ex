defmodule Maru.Builder.Plugs.Server do
  @moduledoc """
  Compile `Maru.Router` module to a `Plug` and generate endpoint functions.
  """

  @doc false
  def compile(%Macro.Env{module: module}=env) do
    config      = (Application.get_env(:maru, module) || [])[:versioning] || []
    extend_opts = Module.get_attribute(module, :extend)
    routes      = Module.get_attribute(module, :routes) ++
                  Module.get_attribute(module, :mounted)
    extended    = Maru.Builder.Extend.take_extended(routes, extend_opts)
    routes      = routes ++ extended

    adapter = Maru.Builder.Versioning.get_adapter(config[:using])

    pipeline = [
      Module.get_attribute(module, :plugs_before) |> Enum.reverse,
      adapter.plug(config),
      [ {:route, [], true},
        {Maru.Plugs.NotFound, [], true},
      ],
    ] |> Enum.concat |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    exceptions =
      Module.get_attribute(module, :exceptions)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Exceptions.make_rescue_block/1)
      |> List.flatten

    routes_block =
      Enum.map(routes, fn route ->
        Maru.Builder.Route.dispatch(route, env, adapter)
      end)

    method_not_allow_block =
      Enum.group_by(routes, fn route -> {route.version, route.path} end)
      |> Enum.map(fn {{version, path}, routes} ->
        unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
          Maru.Builder.Route.dispatch_405(version, path, adapter)
        end
      end)

    quote do
      unquote(routes_block)
      unquote(method_not_allow_block)

      defp route(conn, _), do: conn

      def init(_), do: []

      def call(unquote(conn), _) do
        unquote(body)
      end

      if not Enum.empty?(@exceptions) do
        defoverridable [call: 2]
        def call(var!(conn), opts) do
          try do
            super(var!(conn), opts)
          rescue
            unquote(exceptions)
          end
        end
      end
    end
  end

end
