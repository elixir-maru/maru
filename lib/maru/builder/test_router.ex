defmodule Maru.Builder.TestRouter do

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    router = Module.get_attribute(module, :router)
    fathers = Module.get_attribute(module, :fathers)
    with_exception_handlers = Module.get_attribute(module, :with_exception_handlers)
    mount_link = Maru.Builder.MountLink.get_mount_link(router, fathers)
    mount_plugs =
      Enum.reduce(mount_link, [], fn(x, acc) ->
        Maru.Struct.Plug.merge(acc, x.__plugs__)
      end)
    routes =
      Enum.map(router.__routes__, fn(route) ->
        plugs =
          Enum.reduce(route.plugs, mount_plugs, fn(x, acc) ->
            Maru.Struct.Plug.merge(acc, x)
          end)
        route_mount_link =
          if with_exception_handlers do
            mount_link
          else
            route.mount_link
          end
        %{route | mount_link: route_mount_link, plugs: plugs}
      end)

    version_adapter = Maru.Builder.Versioning.Test
    pipeline = [
      {Maru.Plugs.SaveConn, [], true},
      {:route, [], true},
      {Maru.Plugs.NotFound, [], true},
    ] |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    routes_block = Maru.Builder.make_routes_block(routes, env, version_adapter)
    method_not_allowed_block = Maru.Builder.make_method_not_allowed_block(routes, version_adapter)

    quote do
      unquote(routes_block)
      unquote(method_not_allowed_block)
      defp route(conn, _), do: conn

      def maru_test_call(unquote(conn)) do
        unquote(body)
      end
    end
  end
end
