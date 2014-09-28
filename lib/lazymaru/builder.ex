defmodule Lazymaru.Builder do
  alias Lazymaru.Router.Resource
  alias Lazymaru.Router.Endpoint
  alias Lazymaru.Router.Path

  @methods [:get, :post, :put, :patch, :delete, :head, :options]
  @namespaces [:namepsace, :group, :resource, :resources, :segment]

  defmacro __using__(_) do
    quote do
      use LazyHelper.Response
      import Plug.Builder, only: [plug: 1, plug: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :plugs, accumulate: true
      Module.register_attribute __MODULE__, :lazymaru_router_plugs, accumulate: true
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
      @resource %Resource{}
      @param_context %{}
      @desc nil
      @exception nil
      @before_compile unquote(__MODULE__)
      def init(_), do: []
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    lazymaru_router_plugs = Module.get_attribute(module, :lazymaru_router_plugs)
    {conn, body} =
      [ if Lazymaru.Config.is_server?(module) do [{Lazymaru.Plugs.NotFound, []}] else [] end,
        lazymaru_router_plugs,
        [{:endpoint, []}, {Lazymaru.Plugs.Prepare, []}],
        if Lazymaru.Config.is_server?(module) do [{Plug.Parsers, parsers: [:urlencoded, :multipart], accept: ["*/*"]}] else [] end,
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
      @lazymaru_router_plugs {unquote(plug), unquote(opts)}
    end
  end


  defmacro route_param(param, [do: block]) do
    quote do
      %Resource{path: path, params: param_context} = resource = @resource
      @resource %{ resource |
                   path: path ++ [unquote(param)],
                   params: param_context |> Dict.merge @param_context
                 }
      @param_context %{}
      unquote(block)
      @resource resource
    end
  end

  Module.eval_quoted __MODULE__, (for namespace <- @namespaces do
    quote do
      defmacro unquote(namespace)([do: block]), do: block
      defmacro unquote(namespace)(path, [do: block]) do
        quote do
          %Resource{path: path} = resource = @resource
          @resource %{resource | path: path ++ [unquote(to_string path)]}
          unquote(block)
          @resource resource
        end
      end
    end
  end)


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
        params: @resource.params |> Dict.merge(@param_context),
        block: unquote(ep.block),
      } |> Macro.escape
      @param_context %{}
      @desc nil
    end
  end

  defmacro params([do: block]) do
    quote do
      unquote(block)
    end
  end

  defmacro requires(attr_name, options \\ []) do
    param(attr_name, options, true)
  end

  defmacro optional(attr_name, options \\ []) do
    param(attr_name, options, false)
  end

  defp param(attr_name, options, required?) do
    # TODO safe_concat?
    parser = case options[:type] do
       nil -> nil
       {:__aliases__, _, [t]} -> [Lazymaru.ParamType, t] |> Module.concat
       t when is_atom(t) ->
         [ Lazymaru.ParamType, t |> Atom.to_string |> Lazymaru.Utils.upper_camel_case |> String.to_atom
         ] |> Module.concat
    end
    quote do
      @param_context @param_context |> Dict.put unquote(attr_name), %{
        value: nil, default: unquote(options[:default]),
        required: unquote(required?), parser: unquote(parser),
        validators: unquote(options) |> Dict.drop [:type, :default] |> Macro.escape
      }
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
      @lazymaru_router_plugs {Lazymaru.Plugs.Router, [router: unquote(module), resource: @resource]}
    end
  end
end
