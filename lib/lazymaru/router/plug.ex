defmodule Lazymaru.Router.Plug do
  def dispatch(ep) do
    helpers_block = for i <- ep.helpers do
      quote do
        import unquote(i)
      end
    end

    params_block = ep.path |> Enum.filter(&is_atom/1) |> decode_params ep.params
    path = ep.path |> Enum.map fn x when is_atom(x) -> Macro.var(x, nil); x -> x end

    quote do
      def call(%Plug.Conn{method: unquote(ep.method),
                          path_info: unquote(path)}=var!(conn), opts) do
        unquote(helpers_block)
        unquote(params_block)
        unquote(ep.block)
      end
    end
  end

  def decode_params(path_params, router_params) do
    router_params = router_params |> Lazymaru.Router.Params.merge Lazymaru.Router.Params.default
    quote do
      var!(conn) = Plug.Parsers.call(var!(conn), [parsers: unquote(router_params.parsers), limit: 80_000_000])
      var!(params) = unquote(router_params.params |> Macro.escape) |> Enum.reduce(
        [ unquote(path_params), unquote(path_params |> Enum.map &(Macro.var &1, nil))
        ] |> List.zip |> Enum.into(%{}),
        fn (i, r) ->
          case { r[i[:param]] || var!(conn).params[i[:param] |> to_string] || i[:default], i[:required]
               } do
            {nil, false} -> r
            {nil, true}  -> LazyException.InvalidFormatter
                         |> raise [reason: :required, param: i[:param], option: i]
            {value, _}   -> r |> Dict.merge Lazymaru.Router.Plug.parse_param(value, i)
          end
        end)
    end
  end

  def parse_param(value, param) do
    try do
      param[:parser].from(value) |> Lazymaru.Router.Plug.check_param(param)
    rescue
      ArgumentError ->
        LazyException.InvalidFormatter |> raise [reason: :illegal, param: param[:param], option: param]
    end
  end

  def check_param(value, param) do
    [ regexp: fn(x) -> Regex.match?(x, value |> to_string) end,
      range: fn(x) -> Enum.member?(x, value) end,
    ] |> check_param(value, param)
  end
  def check_param([], value, param), do: [{param[:param], value}]
  def check_param([{k, f}|t], value, param) do
    if Dict.has_key?(param, k) and not f.(param[k]) do
      LazyException.InvalidFormatter |> raise [reason: :unformatted, param: param[:param], option: param]
    end
    check_param(t, value, param)
  end
end
