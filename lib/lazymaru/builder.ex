defmodule Lazymaru.Builder do
  alias Lazymaru.Router.Resource
  alias Lazymaru.Router.Endpoint
  alias Lazymaru.Router.Path

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  defmacro __using__(_) do
    quote do
      use Lazymaru.Helpers.Response
      import Lazymaru.Builder.Namespaces
      import Plug.Builder, only: [plug: 1, plug: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :plugs, accumulate: true
      Module.register_attribute __MODULE__, :lazymaru_router_plugs, accumulate: true
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
      @resource %Resource{}
      @param_context []
      @desc nil
      @group []
      @exception nil
      @before_compile unquote(__MODULE__)
      def init(_), do: []
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    lazymaru_router_plugs = Module.get_attribute(module, :lazymaru_router_plugs)
    {conn, body} =
      [ if Lazymaru.Config.is_server?(module) do
          [{Lazymaru.Plugs.NotFound, [], true}]
        else [] end,
        lazymaru_router_plugs,
        [{:endpoint, [], true}, {Lazymaru.Plugs.Prepare, [], true}],
        if Lazymaru.Config.is_server?(module) do
          [{Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], accept: ["*/*"], json_decoder: Poison], true}]
        else [] end,
        plugs
      ] |> Enum.concat |> Plug.Builder.compile

    quote do
      for i <- @endpoints do
        Module.eval_quoted __MODULE__, (i |> Code.eval_quoted |> elem(0) |> Endpoint.dispatch), [], __ENV__
      end
      defp endpoint(conn, _), do: conn
      def call(unquote(conn), _) do
        unquote(body)
      end

      if Module.defines? __MODULE__, {:error, 2} do
        defoverridable [call: 2]
        def call(conn, opts) do
          try do
            super(conn, opts)
          rescue
            e -> error(conn, e)
          end
        end
      end
    end
  end

  defmacro lazymaru_router_plug(plug, opts \\ []) do
    quote do
      @lazymaru_router_plugs {unquote(plug), unquote(opts), true}
    end
  end


  Module.eval_quoted __MODULE__, (for method <- @methods do
    quote do
      defmacro unquote(method)(path \\ "", [do: block]) do
        %{ method: unquote(method) |> to_string |> String.upcase,
           path: path |> Path.split,
           block: block |> Macro.escape,
         } |> endpoint
      end
    end
  end)

  defp endpoint(ep) do
    quote do
      @endpoints %Endpoint{
        method: unquote(ep.method), desc: @desc,
        path: @resource.path ++ unquote(ep.path),
        param_context: @resource.param_context ++ @param_context,
        block: unquote(ep.block),
      } |> Macro.escape
      @param_context []
      @desc nil
    end
  end

  defmacro params(block) do
    quote do
      import Lazymaru.Builder.Namespaces, only: []
      import Lazymaru.Builder.Params
      @group []
      unquote(block)
      import Lazymaru.Builder.Params, only: []
      import Lazymaru.Builder.Namespaces
    end
  end

  defmacro helpers([do: block]) do
    quote do
      unquote(block)
    end
  end

  defmacro helpers({_, _, mod}) do
    quote do
      import unquote(Module.concat mod)
    end
  end


  defmacro desc(desc) do
    quote do
      @desc unquote(desc)
    end
  end

  defmacro mount({_, _, mod}) do
    module = Module.concat mod
    quote do
      @lazymaru_router_plugs {Lazymaru.Plugs.Router, [router: unquote(module), resource: @resource], true}
    end
  end

end
