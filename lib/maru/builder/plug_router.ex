defmodule Maru.Builder.PlugRouter do

  @doc false
  def __before_compile__(%Macro.Env{module: module}=env, routes) do
    plugs_before    = Module.get_attribute(module, :plugs_before) |> Enum.reverse
    version_config  = (Application.get_env(:maru, module) || [])[:versioning] || []
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

    routes_block = Maru.Builder.make_routes_block(routes, env, version_adapter)
    method_not_allowed_block = Maru.Builder.make_method_not_allowed_block(routes, version_adapter)

    [ quote do
        unquote(routes_block)
        unquote(method_not_allowed_block)
        defp route(conn, _), do: conn

        def init(_), do: []
      end,

      if Module.get_attribute(module, :exceptions) != [] do
        quote do
          def call(unquote(conn), _) do
            __error_handler__(fn -> unquote(body) end).()
          end
        end
      else
        quote do
          def call(unquote(conn), _) do
            unquote(body)
          end
        end
      end
    ]
  end

end
