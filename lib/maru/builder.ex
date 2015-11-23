defmodule Maru.Builder do
  alias Maru.Router.Resource
  alias Maru.Router.Endpoint

  @doc false
  defmacro __using__(_) do
    quote do
      use Maru.Helpers.Response
      import Maru.Builder.Namespaces
      import Maru.Builder.Methods
      import Maru.Builder.Exceptions
      import Maru.Builder.DSLs
      import Plug.Builder, only: [plug: 1, plug: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :plugs, accumulate: true
      Module.register_attribute __MODULE__, :maru_router_plugs, accumulate: true
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      Module.register_attribute __MODULE__, :exceptions, accumulate: true
      @version nil
      @extend nil
      @resource %Resource{}
      @param_context []
      @desc nil
      @before_compile unquote(__MODULE__)
      def init(_), do: []
    end
  end


  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    plugs = Module.get_attribute(module, :plugs)
    maru_router_plugs = Module.get_attribute(module, :maru_router_plugs)
    extend = Module.get_attribute(module, :extend)
    config = Maru.Config.server_config(module)
    pipeline = [
      if is_nil(config) do [] else
        [{Maru.Plugs.NotFound, [], true}]
      end,
      if is_nil(extend) do [] else
        [extend]
      end,
      maru_router_plugs,
      [{:endpoint, [], true}],
      if is_nil(config) or is_nil(config[:versioning]) do [] else
        [{Maru.Plugs.Version, config[:versioning], true}]
      end,
      if is_nil(config) do [] else
        [{Plug.Parsers, [parsers: [Maru.Parsers.URLENCODED, Maru.Parsers.JSON, Plug.Parsers.MULTIPART], pass: ["*/*"], json_decoder: Poison], true}]
      end,
      [{Maru.Plugs.Prepare, [], true}],
      plugs,
    ] |> Enum.concat
    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    exceptions =
      Module.get_attribute(module, :exceptions)
   |> Enum.reverse
   |> Enum.map(&Maru.Builder.Exceptions.make_rescue_block/1)
   |> List.flatten

    quote do
      @endpoints |> Enum.reverse |> Enum.map fn ep ->
        Module.eval_quoted __MODULE__, (ep |> Endpoint.dispatch), [], __ENV__
      end

      @endpoints
   |> Enum.group_by(fn ep -> {ep.version, ep.path} end)
   |> Enum.map fn {{version, path}, endpoints} ->
        unless Enum.any?(endpoints, fn i -> i.method == {:_, [], nil} end) do
          Module.eval_quoted __MODULE__, (Endpoint.dispatch_405 version, path), [], __ENV__
        end
      end

      defp endpoint(conn, _), do: conn


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

      if Mix.env in [:dev, :test] do
        def __endpoints__, do: @endpoints
        def __routers__, do: @maru_router_plugs
        def __version__, do: @version
        def __extend__, do: @extend
      end
    end
  end
end
