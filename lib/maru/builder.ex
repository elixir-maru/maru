defmodule Maru.Builder do
  alias Maru.Router.Resource
  alias Maru.Router.Endpoint
  alias Maru.Router.Path

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  defmacro __using__(_) do
    quote do
      use Maru.Helpers.Response
      import Maru.Builder.Namespaces
      import Plug.Builder, only: [plug: 1, plug: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :plugs, accumulate: true
      Module.register_attribute __MODULE__, :maru_router_plugs, accumulate: true
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
      @version nil
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
    maru_router_plugs = Module.get_attribute(module, :maru_router_plugs)
    {conn, body} =
      [ if Maru.Config.is_server?(module) do
          [{Maru.Plugs.NotFound, [], true}]
        else [] end,
        maru_router_plugs,
        [{:endpoint, [], true}, {Maru.Plugs.Prepare, [], true}],
        if Maru.Config.is_server?(module) do
          [{Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Poison], true}]
        else [] end,
        plugs,
      ] |> Enum.concat |> Plug.Builder.compile

    quote do
      for i <- @endpoints do
        Module.eval_quoted __MODULE__, (i |> Code.eval_quoted |> elem(0) |> Endpoint.dispatch), [], __ENV__
      end
      defp endpoint(conn, _), do: conn

      case @version do
        nil ->
          def call(unquote(conn), _) do
            unquote(body)
          end
        {v, opts} ->
          @v v
          @opts opts
          def call(unquote(conn)=c, _) do
            unquote(conn) = unquote(conn) |> Maru.Plugs.Version.call(Maru.Plugs.Version.init(@opts))
            case unquote(conn).private.maru_version do
              @v -> unquote(body)
              _  -> c
            end
          end
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

      if Mix.env == :dev do
        def __endpoints__, do: @endpoints |> Code.eval_quoted |> elem(0)
        def __routers__, do: @maru_router_plugs
      end
    end
  end

  defmacro maru_router_plug(plug, opts \\ []) do
    quote do
      @maru_router_plugs {unquote(plug), unquote(opts), true}
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
      import Maru.Builder.Namespaces, only: []
      import Maru.Builder.Params
      @group []
      unquote(block)
      import Maru.Builder.Params, only: []
      import Maru.Builder.Namespaces
    end
  end

  defmacro version(v, opts) do
    key = opts |> Keyword.get :using, :path
    key in [:path, :param, :accept_version_header] || raise "unsupported version type: #{inspect key}"
    quote do
      @version {unquote(v), unquote(opts)}
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
      @maru_router_plugs {Maru.Plugs.Router, [router: unquote(module), resource: @resource], true}
    end
  end

end
