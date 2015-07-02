defmodule Maru.Builder do
  alias Maru.Router.Resource
  alias Maru.Router.Endpoint
  alias Maru.Router.Path

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  defmacro __using__(_) do
    quote do
      import Maru.Helpers.Response
      import Maru.Builder.Namespaces
      import Plug.Builder, only: [plug: 1, plug: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :plugs, accumulate: true
      Module.register_attribute __MODULE__, :maru_router_plugs, accumulate: true
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      Module.register_attribute __MODULE__, :exceptions, accumulate: true
      @version nil
      @resource %Resource{}
      @param_context []
      @desc nil
      @group []
      @before_compile unquote(__MODULE__)
      def init(_), do: []
    end
  end


  defmacro rescue_from(:all, [as: error_var], [do: block]) do
    quote do
      @exceptions {:all, unquote(error_var |> Macro.escape), unquote(block |> Macro.escape)}
    end
  end

  defmacro rescue_from(error, [as: error_var], [do: block]) do
    quote do
      @exceptions {unquote(error), unquote(error_var |> Macro.escape), unquote(block |> Macro.escape)}
    end
  end

  defmacro rescue_from(:all, [do: block]) do
    quote do
      @exceptions {:all, unquote(block |> Macro.escape)}
    end
  end

  defmacro rescue_from(error, [do: block]) do
    quote do
      @exceptions {unquote(error), unquote(block |> Macro.escape)}
    end
  end


  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    plugs = Module.get_attribute(module, :plugs)
    maru_router_plugs = Module.get_attribute(module, :maru_router_plugs)
    pipeline = [
      if Maru.Config.is_server?(module) do
        [{Maru.Plugs.NotFound, [], true}]
      else [] end,
      maru_router_plugs,
      [{:endpoint, [], true}, {Maru.Plugs.Prepare, [], true}],
      if Maru.Config.is_server?(module) do
        [{Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Poison], true}]
      else [] end,
      plugs,
    ] |> Enum.concat
    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    exceptions = Module.get_attribute(module, :exceptions) |> Enum.map(
      fn
        {:all, block} ->
          quote do
            _ ->
              resp = unquote(block)
              Maru.Router.Endpoint.send_resp(var!(conn), resp)
          end
        {error, block} ->
          quote do
            unquote(error) ->
              resp = unquote(block)
              Maru.Router.Endpoint.send_resp(var!(conn), resp)
          end
        {:all, error_var, block} ->
          quote do
            unquote(error_var) ->
              resp = unquote(block)
              Maru.Router.Endpoint.send_resp(var!(conn), resp)
          end
        {error, error_var, block} ->
          quote do
            unquote(error_var) in unquote(error) ->
              resp = unquote(block)
              Maru.Router.Endpoint.send_resp(var!(conn), resp)
          end
    end) |> List.flatten |> Enum.reverse

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


      cond do
        not Enum.empty? @exceptions ->
          defoverridable [call: 2]
          def call(var!(conn), opts) do
            try do
              super(var!(conn), opts)
            rescue
              unquote(exceptions)
            end
          end
        Module.defines? __MODULE__, {:error, 2} ->
          IO.write :stderr, "warning: error/2 is deprecated, in faver of rescue_from/2 and rescue_from/3.\n"
          defoverridable [call: 2]
          def call(conn, opts) do
            try do
              super(conn, opts)
            rescue
              e -> error(conn, e)
            end
          end
        true -> nil
      end

      if Mix.env == :dev do
        def __endpoints__, do: @endpoints |> Code.eval_quoted |> elem(0)
        def __routers__, do: @maru_router_plugs
        def __version__ do
          case @version do
            {v, _} -> v
            nil    -> nil
          end
        end
      end
    end
  end

  defmacro maru_router_plug(plug, opts \\ []) do
    quote do
      @maru_router_plugs {unquote(plug), unquote(opts), true}
    end
  end

  defmacro prefix(path) do
    path = Path.split path
    quote do
      %Resource{path: path} = resource = @resource
      @resource %{resource | path: path ++ (unquote path)}
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
      import Maru.Helpers.Params
      import Kernel, except: [use: 1]
      unquote(block)
    end
  end

  defmacro helpers({_, _, mod}) do
    module = Module.concat mod
    quote do
      import Maru.Helpers.Params
      import unquote(module)
      unquote(module).__shared_params__ |> Enum.each &(@shared_params &1)
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
