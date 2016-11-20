defmodule Maru.Builder.TestRouter do

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    router = Module.get_attribute(module, :router)
    fathers = Module.get_attribute(module, :fathers)
    mount_plugs =
      Maru.Builder.MountLink.get_mount_link(router, fathers)
      |> Enum.reduce([], fn(x, acc) ->
        Maru.Struct.Plug.merge(acc, x.__plugs__)
      end)
    routes =
      Enum.map(router.__routes__, fn(route) ->
        plugs =
          Enum.reduce(route.plugs, mount_plugs, fn(x, acc) ->
            Maru.Struct.Plug.merge(acc, x)
          end)
        %{route | plugs: plugs}
      end)

    version_adapter = Maru.Builder.Versioning.Test
    pipeline = [
      {Maru.Plugs.SaveConn, [], true},
      {:route, [], true},
      {Maru.Plugs.NotFound, [], true},
    ] |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    routes_block = Maru.Builder.make_routes_block(routes, env, version_adapter)
    method_not_allow_block = Maru.Builder.make_method_not_allow_block(routes, version_adapter)

    quote do
      unquote(routes_block)
      unquote(method_not_allow_block)
      defp route(conn, _), do: conn

      def maru_test_call(unquote(conn)) do
        unquote(body)
      end
    end
  end
end
