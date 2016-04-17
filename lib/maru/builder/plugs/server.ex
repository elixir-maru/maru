defmodule Maru.Builder.Plugs.Server do
  @moduledoc """
  Compile `Maru.Router` module to a `Plug` and generate endpoint functions.
  """

  @doc false
  def compile(%Macro.Env{module: module}=env) do
    config      = (Application.get_env(:maru, module) || [])[:versioning] || []
    extend_opts = Module.get_attribute(module, :extend)
    endpoints   = Module.get_attribute(module, :endpoints) ++
                  Module.get_attribute(module, :mounted)
    extended    = Maru.Builder.Extend.take_extended(endpoints, extend_opts)
    endpoints   = endpoints ++ extended

    adapter = Maru.Builder.Versioning.get_adapter(config[:using])

    pipeline = [
      adapter.plug(config),
      [ {:endpoint, [], true},
        {Maru.Plugs.NotFound, [], true}
      ],
    ] |> Enum.concat |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    exceptions =
      Module.get_attribute(module, :exceptions)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Exceptions.make_rescue_block/1)
      |> List.flatten

    endpoints_block =
      Enum.map(endpoints, fn ep ->
        Maru.Builder.Endpoint.dispatch(ep, env, adapter)
      end)

    method_not_allow_block =
      Enum.group_by(endpoints, fn ep -> {ep.version, ep.path} end)
      |> Enum.map(fn {{version, path}, endpoints} ->
        unless Enum.any?(endpoints, fn i -> i.method == {:_, [], nil} end) do
          Maru.Builder.Endpoint.dispatch_405(version, path, adapter)
        end
      end)

    quote do
      unquote(endpoints_block)
      unquote(method_not_allow_block)

      defp endpoint(conn, _), do: conn

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
