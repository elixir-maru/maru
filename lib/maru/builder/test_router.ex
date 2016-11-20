defmodule Maru.Builder.TestRouter do

  @doc false
  def __before_compile__(%Macro.Env{}=env, routes) do
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

      def init(_), do: []
      def call(unquote(conn), _) do
        unquote(body)
      end

      def __version__, do: Maru.Struct.Resource.get_version
    end
  end

end
