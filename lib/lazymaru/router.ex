defmodule Lazymaru.Router do
  alias Lazymaru.Router.Resource
  alias Lazymaru.Router.Params
  alias Lazymaru.Router.Endpoint
  alias Lazymaru.Router.Path
  alias Lazymaru.Router.Plug, as: LazyPlug

  @methods [:get, :post, :put, :patch, :delete, :head, :options]
  @namespaces [:namepsace, :group, :resource, :resources, :segment]

  defmacro __using__(opts \\ []) do
    quote do
      use LazyHelper.Response
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__,
             :endpoints, accumulate: true, persist: false
      Module.register_attribute __MODULE__,
             :helpers, accumulate: true, persist: false
      @resource %Resource{}
      @param_context nil
      @desc nil
      @as_plug unquote(opts[:as_plug]) || false
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def endpoints, do: @endpoints |> Enum.reverse
      if @as_plug do
        def init(opts), do: opts
        for i <- @endpoints do
          Module.eval_quoted __MODULE__, (i |> Code.eval_quoted |> elem(0) |> LazyPlug.dispatch), [], __ENV__
        end
      end
    end
  end


  defmacro route_param(param, [do: block]) do
    quote do
      %Resource{path: path, params: param_context} = resource = @resource
      @resource %{ resource |
                   path: path ++ [unquote(param)],
                   params: param_context |> Params.merge(@param_context)
                 }
      @param_context nil
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
        method: unquote(ep.method),
        desc: @desc, helpers: @helpers,
        path: @resource.path ++ unquote(ep.path),
        params: @resource.params |> Params.merge(@param_context),
        block: unquote(ep.block),
      } |> Macro.escape
      @param_context nil
      @desc nil
    end
  end


  defmacro params(parsers \\ [], [do: block]) do
    quote do
      @param_context %Params{parsers: unquote(parsers |> List.wrap)}
      unquote(block)
    end
  end

  defmacro requires(param, options \\ []) do
    param(param, options, true)
  end

  defmacro optional(param, options \\ []) do
    param(param, options, false)
  end

  defp param(param, options, required?) do
    type = case options[:type] || :string do
       {:__aliases__, _, [t]} -> t
       t when is_atom(t) ->
         t |> Atom.to_string |> String.capitalize |> String.to_atom
    end
    param = [ param: param, required: required?,
              parser: [LazyParamType, type] |> Module.concat
            ] |> Dict.merge(options) |> Dict.drop([:type])
    quote do
      %Params{params: params} = param_context = @param_context
      @param_context %{param_context | params: params ++ [unquote param]}
    end
  end


  defmacro helpers([do: block]) do
    quote do
      unquote(block)
      @helpers __MODULE__
    end
  end

  defmacro helpers({_, _, mod}) do
    quote do
      @helpers unquote(Module.concat mod)
    end
  end


  defmacro desc(desc) do
    quote do
      @desc unquote(desc)
    end
  end


  defmacro mount({_, _, mod}) do
    module = Module.concat(mod)
    quote do
      require unquote(module)
    end
    for ep <- module.endpoints do
      quote do
        ep = unquote(ep)
        @endpoints %{ ep |
          path: @resource.path ++ ep.path,
          params: @resource.params |> Params.merge(ep.params)
        } |> Macro.escape
        @param_context nil
        @desc nil
      end
    end
  end

end