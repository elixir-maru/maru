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

  defmacro map_params(n) do
    Enum.map 0..n,
      fn(x) ->
          param_name = "param_#{x}" |> binary_to_atom
          quote do
            var!(unquote(param_name))
          end
      end
  end

  def map_params_path(path), do: map_params_path(path, 0, [])
  def map_params_path([], _, r), do: r |> Enum.reverse
  def map_params_path([h|t], n, r) when is_binary(h) do
    new_path = quote do: var!(unquote("param_#{n}" |> binary_to_atom))
    map_params_path(t, n+1, [new_path|r])
  end
  def map_params_path([h|t], n, r) do
    map_params_path(t, n, [h|r])
  end

  defmacro dispatch(Recs.Endpoint[params: []]=ep) do
    new_block = quote do
      var!(:params) = []
      unquote(ep.block)
    end |> Macro.escape
    quote do
      @endpoints {unquote(ep.method), unquote(ep.path), unquote(new_block)}
    end
  end

  defmacro dispatch(ep) when is_record(ep, Recs.Endpoint) do
    path = map_params_path(ep.path) |> Macro.escape
    new_block = quote do
      var!(:params) = List.zip [unquote(ep.params), map_params(unquote(length(ep.params)-1))]
      unquote(ep.block)
    end |> Macro.escape
    quote do
      @endpoints {unquote(ep.method), unquote(path), unquote(new_block)}
    end
  end

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
  def define_namespace(Recs.Endpoint[block: {namespace, _, [path, [do: block]]}]=ep)
  when namespace in [:namepsace, :group, :resource, :resources, :segment] do
    new_path = ep.path ++ [path]
    new_ep = ep.update([path: new_path,
                        block: block,
                      ])
    define_namespace(new_ep)
  end
  def define_namespace(Recs.Endpoint[block: {:route_param, _, [param, [do: block]]}]=ep) do
    new_path = ep.path ++ ["#{param}_#{length(ep.params)}"]
    new_ep = ep.update([path: new_path,
                        params: ep.params ++ [param],
                        block: block,
                      ])
    define_namespace(new_ep)
  end
  def define_namespace(Recs.Endpoint[block: {method, _, blocks}]=ep)
  when method in [:get, :post, :put, :option, :head, :delete] do
    case blocks do
      [path, block] ->
        new_ep = path |> (String.split "/") |>
        Enum.reduce ep.update([method: method, block: block]),
          fn("", ep) -> ep
            (":" <> param, ep) ->
              new_path = ep.path ++ ["#{param}_#{length(ep.params)}"]
              new_params = ep.params ++ [param |> binary_to_atom]
              ep.update([path: new_path,
                         params: new_params
                       ])
            (path, ep) ->
              new_path = ep.path ++ [path |> binary_to_atom]
              ep.update([path: new_path])
          end
        quote do
          dispatch(unquote(new_ep))
        end
      [block] ->
        new_ep = ep.update([method: method, block: block])
        quote do
          dispatch(unquote(new_ep))
        end
    end
  end
  def define_namespace(Recs.Endpoint[path: top_path, block: {:mount, _, [{_, _, mod}]}]=ep) do
    lc {m, p, b} inlist Module.safe_concat(mod).endpoints do
      new_path = Macro.escape(top_path ++ p)
      new_ep = ep.update([method: m,
                          path: new_path,
                          block: b,
                        ])
      quote do
        dispatch(unquote(new_ep))
      end
    end
  end
  def define_namespace(ep) do
    IO.inspect ep.block
  end


  defmacro mount({_, _, mod}) do
    endpoints = Module.safe_concat(mod).endpoints |> Macro.escape
    quote location: :keep, bind_quoted: [endpoints: endpoints] do
      Enum.each endpoints, fn {method, path, block} ->
        def service(unquote(method), unquote(path)) do
          unquote(block)
        end
      end
    end
  end

  defmacro route_param(param, [do: block]) do
    Recs.Endpoint[path: ["param_0"], block: block, params: [param]] |> define_namespace
  end

  def new_namespace(path, [do: block]) do
    Recs.Endpoint[path: [path], block: block] |> define_namespace
  end
  defmacro group(path, block),     do: new_namespace(path, block)
  defmacro resources(path, block), do: new_namespace(path, block)
  defmacro resource(path, block),  do: new_namespace(path, block)
  defmacro segment(path, block),   do: new_namespace(path, block)

  def new_endpoint(method, path, block) do
    Recs.Endpoint[block: {method, [], [path|block]}] |> define_namespace
  end
  defmacro get(path // "", block),    do: new_endpoint(:get, path, block)
  defmacro post(path // "", block),   do: new_endpoint(:post, path, block)
  defmacro put(path // "", block),    do: new_endpoint(:put, path, block)
  defmacro option(path // "", block), do: new_endpoint(:option, path, block)
  defmacro head(path // "", block),   do: new_endpoint(:head, path, block)
  defmacro delete(path // "", block), do: new_endpoint(:delete, path, block)
end