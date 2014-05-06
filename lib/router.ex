defmodule Lazymaru.Router do
  @methods [:get, :post, :put, :options, :head, :delete]
  @namespaces [:namepsace, :group, :resource, :resources, :segment]

  defmodule Endpoint do
     [ method: nil, path: [], desc: "", params: [],
       block: nil, params_block: nil, helpers: [],
     ] |> defstruct
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__,
             :endpoints, accumulate: true, persist: false
      Module.register_attribute __MODULE__,
             :helpers, accumulate: true, persist: false

      @params_block nil
      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_) do
    quote do
      def endpoints, do: @endpoints
      def helpers, do: @helpers
    end
  end


  defmacro endpoint(ep) do
    quote do
      @endpoints %Endpoint{ method: unquote(ep.method), path: unquote(ep.path), helpers: unquote(ep.helpers) ++ @helpers,
                            params: unquote(ep.params), block: unquote(ep.block |> Macro.escape),
                            params_block: @params_block || unquote(ep.params_block |> Macro.escape),
                          }
      @params_block nil
    end
  end


  defmacro endpoint(ep, :mount) do
    quote do
      @endpoints %Endpoint{ method: unquote(ep.method), path: unquote(ep.path), helpers: unquote(ep.helpers),
                            params: unquote(ep.params), block: unquote(ep.block |> Macro.escape),
                            params_block: unquote(ep.params_block |> Macro.escape),
                          }
    end
  end


  def define_endpoint(ep, blocks), do: define_endpoint(ep, blocks, [])
  def define_endpoint(_, [], r), do: r
  def define_endpoint(ep, [{:desc, _, [desc]}|t], r) do
    %{ep | desc: desc} |> define_endpoint(t, r)
  end
  def define_endpoint(ep, [{:params, _, [[do: block]]}|t], r) do
    new_params_block = quote do
      var!(:conn) = Plug.Parsers.call(var!(:conn), [parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART], limit: 80_000_000])
      unquote(block)
    end
    %{ep | params_block: new_params_block} |> define_endpoint(t, r)
  end
  def define_endpoint(ep, [h|t], r) do
    new_r = %{ep | block: h} |> define_namespace
    %{ep | desc: "", params_block: nil} |> define_endpoint(t, [new_r | r])
  end


  def define_namespace(%Endpoint{block: {:__block__, _, blocks}}=ep) do
    define_endpoint(ep, blocks)
  end

  def define_namespace(%Endpoint{block: {namespace, _, [path, [do: block]]}}=ep)
  when namespace in @namespaces do
    %{ep | path: ep.path ++ [path |> to_string], block: block} |> define_namespace
  end

  def define_namespace(%Endpoint{block: {:route_param, _, [param, [do: block]]}}=ep) do
    %{ep | path: ep.path ++ [:param], params: ep.params ++ [param], block: block
     } |> define_namespace
  end

  def define_namespace(%Endpoint{block: {method, _, blocks}}=ep)
  when method in @methods do
    case blocks do
      [path, block] ->
        new_ep = path |> to_string |> String.split("/") |>
        Enum.reduce %{ep | method: method, block: block},
          fn("", ep) -> ep
            (":" <> param, ep) ->
              new_path = ep.path ++ [:param]
              new_params = ep.params ++ [:"#{param}"]
              %{ep | path: new_path, params: new_params}
            (path, ep) ->
              %{ep | path: ep.path ++ [path]}
          end
        quote do
          endpoint(unquote(new_ep))
        end
      [block] ->
        new_ep = %{ep | method: method, block: block}
        quote do
          endpoint(unquote(new_ep))
        end
    end
  end

  def define_namespace(%Endpoint{block: {:mount, _, [{_, _, mod}]}}=ep) do
    module = Module.concat(mod)
    quote do
      require unquote(module)
    end
    for %{method: method, path: path, params: params, block: block, params_block: params_block} <- module.endpoints do
      new_path = ep.path ++ path
      new_params = ep.params ++ params
      new_ep = %{ ep | method: method, path: new_path, params: new_params,
                  block: block, params_block: params_block,
                }
      quote do
        endpoint(unquote(new_ep), :mount)
      end
    end
  end

  def define_namespace(ep) do
    IO.inspect ep.block
  end


  defmacro route_param(param, [do: block]) do
    %Endpoint{path: [:param], block: block, params: [param]} |> define_namespace
  end


  Module.eval_quoted __MODULE__, (for namespace <- @namespaces do
    quote do
      defmacro unquote(namespace)([do: block]) do
        ep = %Endpoint{path: [], block: block}
        quote do
          unquote(define_namespace ep)
        end
      end
      defmacro unquote(namespace)(path, [do: block]) do
        ep = %Endpoint{path: [to_string(path)], block: block}
        quote do
          unquote(define_namespace ep)
        end
      end
    end
  end)

  Module.eval_quoted __MODULE__, (for method <- @methods do
    quote do
      defmacro unquote(method)(path \\ "", block) do
        ep = %Endpoint{block: {unquote(method), [], [to_string(path) | block]}}
        quote do
          unquote(define_namespace ep)
        end
      end
    end
  end)



  defmacro params([do: block]) do
    new_params_block = quote do
      var!(:conn) = var!(:conn) |> Plug.Parsers.call([parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART], limit: 80_000_000])
      unquote(block)
    end
    quote do
      @params_block unquote(new_params_block |> Macro.escape)
    end
  end


  defmacro mount({_, _, mod}) do
    module = Module.concat(mod)
    quote do
      require unquote(module)
    end
    for ep <- module.endpoints do
      quote do
        endpoint(unquote(ep), :mount)
      end
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
end