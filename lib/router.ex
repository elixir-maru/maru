defmodule Lazymaru.Router do
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

  defmacro mount({_, _, mod}) do
    endpoints = Module.safe_concat(mod).endpoints |> Macro.escape
    quote bind_quoted: [endpoints: endpoints] do
      Enum.each endpoints, fn {method, path, block} ->
        def service(unquote(method), unquote(path)) do
          unquote(block)
        end
      end
    end
  end

  defmacro map_params(n) do
    Enum.map 0..n,
      fn(x) ->
          param_name = "param_#{x}" |> binary_to_atom
          quote do
            var!(unquote(param_name))
          end
      end
  end

  def map_path(path), do: map_path(path, 0, [])
  def map_path([], _, r), do: r |> Enum.reverse
  def map_path([h|t], n, r) when is_binary(h) do
    new_path = quote do: var!(unquote("param_#{n}" |> binary_to_atom))
    map_path(t, n+1, [new_path|r])
  end
  def map_path([h|t], n, r) do
    map_path(t, n, [h|r])
  end

  defmacro match(method, Recs.Endpoint[params: []]=ep) do
    IO.inspect "match1"
    IO.inspect ep.path
    new_block = quote do
      var!(:params) = []
      unquote(ep.block)
    end |> Macro.escape
    quote do
      IO.inspect "match11"
      @endpoints {unquote(method), unquote(ep.path), unquote(new_block)}
    end
  end

  defmacro match(method, ep) do
    IO.inspect "match2"
    IO.inspect ep.path
    path = map_path(ep.path) |> Macro.escape
    new_block = quote do
      var!(:params) = List.zip [unquote(ep.params), map_params(unquote(length(ep.params)-1))]
      unquote(ep.block)
    end |> Macro.escape
    quote do
      IO.inspect "match22"
      @endpoints {unquote(method), unquote(path), unquote(new_block)}
    end
  end

  defmacro get(ep), do: quote do: match(:get, unquote(ep))
  defmacro post(ep), do: quote do: match(:post, unquote(ep))
  defmacro put(ep), do: quote do: match(:put, unquote(ep))
  defmacro option(ep), do: quote do: match(:option, unquote(ep))
  defmacro head(ep), do: quote do: match(:head, unquote(ep))
  defmacro delete(ep), do: quote do: match(:delete, unquote(ep))


  def define_endpoint(ep, blocks), do: define_endpoint(ep, blocks, [])
  def define_endpoint(_, [], r), do: r
  def define_endpoint(ep, [{:desc, _, [desc]}|t], r) do
    define_endpoint(ep.desc(desc), t, r)
  end
  def define_endpoint(ep, [h|t], r) do
    define_endpoint(ep.desc(""), t, [ep.block(h) |> define_namespace | r])
  end


  def define_namespace(Recs.Endpoint[block: {:__block__, _, blocks}]=ep) do
    define_endpoint(ep, blocks)
  end
  def define_namespace(Recs.Endpoint[block: {nc, v, [path|t]}]=ep)
  when nc in [:namepsace, :group, :resource, :resources, :segment] do
    new_path = ep.path ++ [path]
    new_ep = ep.update([path: new_path])
    {:namespace, v, [new_ep|t]}
  end
  def define_namespace(Recs.Endpoint[block: {:route_param, v, [param|t]}]=ep) do
    new_path = ep.path ++ ["#{param}_#{length(ep.params)}"]
    new_ep = ep.update([ path: new_path,
                         params: ep.params ++ [param]
                      ])
    {:namespace, v, [new_ep|t]}
  end
  def define_namespace(Recs.Endpoint[block: {method, v, [t]}]=ep)
  when method in [:get, :post, :put, :option, :header, :delete] do
    {method, v, [ep.update([method: method, block: t])]}
  end
  def define_namespace(Recs.Endpoint[block: {:mount, _, [mod]}]=ep) do
    {_, _, m} = mod
    blocks = Module.safe_concat(m).endpoints
    |> Enum.map fn {method, path, block} ->
                     new_path = ep.path ++ path
                     new_ep = ep.update([method: method,
                                         path: new_path,
                                         block: block
                                       ])
                     {:match, [], [method, new_ep]} |> Macro.escape
                end
    {:__block__, [], blocks}
  end
  def define_namespace(ep) do
    IO.inspect ep.block
  end


  defmacro namespace(ep, [do: block]) do
    define_namespace(ep.block(block))
  end

  defmacro route_param(param, [do: block]) do
    Recs.Endpoint[path: ["param_0"], block: block, params: [param]] |> define_namespace
  end

  defmacro new_namespace(path, [do: block]) do
    Recs.Endpoint[path: [path], block: block] |> define_namespace
  end

  defmacro group(path, block), do: quote do: new_namespace(unquote(path), unquote(block))
  defmacro resources(path, block), do: quote do: new_namespace(unquote(path), unquote(block))
  defmacro resource(path, block), do: quote do: new_namespace(unquote(path), unquote(block))
  defmacro segment(path, block), do: quote do: new_namespace(unquote(path), unquote(block))
end