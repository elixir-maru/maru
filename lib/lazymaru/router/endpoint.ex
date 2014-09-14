defmodule Lazymaru.Router.Endpoint do
  [ method: nil, path: [], desc: nil, params: [], block: nil, helpers: []
  ] |> defstruct

  def dispatch(ep) do
    path = ep.path |> Enum.map fn x when is_atom(x) -> Macro.var(:_, nil); x -> x end
    params_block = quote do
      var!(params) =
        case var!(conn).private.lazymaru_params do
          [] -> %{}
          param_context -> Lazymaru.Router.Endpoint.parse_params(param_context, var!(conn).params)
        end
    end

    quote do
      defp endpoint(%Plug.Conn{method: unquote(ep.method),
                               private: %{lazymaru_path: unquote(path)}}=var!(conn), []) do
        var!(conn) = Lazymaru.Router.Path.pick_params(var!(conn), unquote(ep.path), unquote(ep.params |> Macro.escape))
        unquote(params_block)
        unquote(ep.block)
      end
    end
  end

  def parse_params(param_context, params) do
    do_parse_params(param_context |> Dict.to_list, params, %{})
  end
  defp do_parse_params([], _params, result), do: result
  defp do_parse_params([{key, option}|t], params, result) do
    case { option[:value] || params[key |> to_string] || option[:default], option[:required] } do
      {nil, false} -> do_parse_params(t, params, result)
      {nil, true}  -> LazyException.InvalidFormatter
                   |> raise [reason: :required, param: key, option: option]
      {value, _}   -> do_parse_params(t, params, result |> Dict.merge check_param(key, value, option))
    end
  end

  defp check_param(key, value, option) do
    parser = option[:parser] || LazyParamType.Term
    validators = option[:validators] || []
    try do
      do_check_param(key, parser.from(value), validators)
    rescue
      ArgumentError ->
        LazyException.InvalidFormatter |> raise [reason: :illegal, param: key, value: value, option: validators]
    end
  end

  defp do_check_param(key, value, validators) do
    [ regexp: fn(x) -> Regex.match?(x, value |> to_string) end,
      range: fn(x) -> Enum.member?(x, value) end,
    ] |> do_check_param(key, value, validators)
  end
  defp do_check_param([], key, value, _validators), do: [{key, value}]
  defp do_check_param([{k, f}|t], key, value, validators) do
    if Dict.has_key?(validators, k) and not f.(validators[k]) do
      LazyException.InvalidFormatter |> raise [reason: :unformatted, param: key, value: value, option: validators]
    end
    do_check_param(t, key, value, validators)
  end
end
