defmodule Lazymaru.Router do
  defmodule Endpoint do
     [ method: nil, path: [], desc: "", params: [],
       block: nil, params_block: nil,
     ] |> defstruct
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__,
             :endpoints, accumulate: true, persist: false

      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_) do
    quote do
      def endpoints, do: @endpoints
    end
  end


  defmacro endpoint(ep) do
    quote do
      @endpoints { unquote(ep.method), unquote(ep.path), unquote(ep.params),
                   unquote(ep.block |> Macro.escape),
                   unquote(ep.params_block |> Macro.escape),
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
  when namespace in [:namepsace, :group, :resource, :resources, :segment] do
    %{ep | path: ep.path ++ [path |> to_string], block: block} |> define_namespace
  end

  def define_namespace(%Endpoint{block: {:route_param, _, [param, [do: block]]}}=ep) do
    %{ep | path: ep.path ++ [:param], params: ep.params ++ [param], block: block
     } |> define_namespace
  end

  def define_namespace(%Endpoint{block: {method, _, blocks}}=ep)
  when method in [:get, :post, :put, :option, :head, :delete] do
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
    for {method, path, params, block} <- module.endpoints do
      new_path = ep.path ++ path
      new_params = ep.params ++ params
      new_ep = %{ep | method: method, path: new_path, params: new_params, block: block}
      quote do
        endpoint(unquote(new_ep))
      end
    end
  end

  def define_namespace(ep) do
    IO.inspect ep.block
  end


  defmacro route_param(param, [do: block]) do
    %Endpoint{path: [:param], block: block, params: [param]} |> define_namespace
  end


  def new_namespace("", [do: block]) do
    %Endpoint{path: [], block: block} |> define_namespace
  end
  def new_namespace(path, [do: block]) do
    %Endpoint{path: [path |> to_string], block: block} |> define_namespace
  end
  defmacro group(path \\ "", block),     do: new_namespace(path, block)
  defmacro resources(path \\ "", block), do: new_namespace(path, block)
  defmacro resource(path \\ "", block),  do: new_namespace(path, block)
  defmacro segment(path \\ "", block),   do: new_namespace(path, block)
  defmacro namespace(path \\ "", block),   do: new_namespace(path, block)


  def new_endpoint(method, "", block) do
    %Endpoint{block: {method, [], [block]}} |> define_namespace
  end
  def new_endpoint(method, path, block) do
    %Endpoint{block: {method, [], [path |> to_string | block]}} |> define_namespace
  end
  defmacro get(path \\ "", block),    do: new_endpoint(:get, path, block)
  defmacro post(path \\ "", block),   do: new_endpoint(:post, path, block)
  defmacro put(path \\ "", block),    do: new_endpoint(:put, path, block)
  defmacro option(path \\ "", block), do: new_endpoint(:option, path, block)
  defmacro head(path \\ "", block),   do: new_endpoint(:head, path, block)
  defmacro delete(path \\ "", block), do: new_endpoint(:delete, path, block)

  defmacro mount({_, _, mod}) do
    module = Module.concat(mod)
    quote do
      require unquote(module)
    end
    for {method, path, params, block, params_block} <- module.endpoints do
      quote do
        @endpoints { unquote(method), unquote(path), unquote(params),
                     unquote(block |> Macro.escape), unquote(params_block |> Macro.escape),
                   }
      end
    end
  end
end