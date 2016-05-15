defmodule Maru.Builder.Plugs.Test do
  @moduledoc """
  Generate functions for `Maru.Test`.
  """

  @doc false
  def compile(%Macro.Env{module: module}=env) do
    routes = Module.get_attribute(module, :routes)
    adapter   = Maru.Builder.Versioning.Test

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
      Enum.group_by(routes, fn ep -> {ep.version, ep.path} end)
      |> Enum.map(fn {{version, path}, routes} ->
        unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
          Maru.Builder.Route.dispatch_405(version, path, adapter)
        end
      end)

    quote do
      unquote(routes_block)
      unquote(method_not_allow_block)

      defp route_test(conn, _), do: conn

      def init(_), do: []

      def call_test(conn, _) do
        conn
        |> route_test([])
        |> case do
          %Plug.Conn{halted: true} = conn -> conn
          %Plug.Conn{}             = conn -> Maru.Plugs.NotFound.call(conn, [])
        end
      end

      if not Enum.empty?(@exceptions) do
        defoverridable [call_test: 2]
        def call_test(var!(conn), opts) do
          try do
            super(var!(conn), opts)
          rescue
            unquote(exceptions)
          end
        end
      end

      def __version__, do: Maru.Struct.Resource.get_version
    end

  end
end
