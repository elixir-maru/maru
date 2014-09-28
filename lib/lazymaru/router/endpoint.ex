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
  defp do_parse_params([{attr_name, option}|t], params, result) do
    case { option[:value] || params[attr_name |> to_string] || option[:default], option[:required] } do
      {nil, false} -> do_parse_params(t, params, result |> Dict.merge [{attr_name, nil}])
      {nil, true}  -> Lazymaru.Exceptions.InvalidFormatter
                   |> raise [reason: :required, param: attr_name, option: option]
      {value, _}   -> do_parse_params(t, params, result |> Dict.merge check_param(attr_name, value, option))
    end
  end

  defp check_param(attr_name, value, option) do
    parser = option[:parser] || Lazymaru.ParamType.Term
    validators = option[:validators] || []
    value = try do
        parser.from(value)
      rescue
        ArgumentError ->
          Lazymaru.Exceptions.InvalidFormatter |> raise [reason: :illegal, param: attr_name, value: value, option: validators]
      end
    do_check_param(validators, attr_name, value)
  end

  defp do_check_param([], attr_name, value), do: [{attr_name, value}]
  defp do_check_param([{validator, option}|t], attr_name, value) do
    validator = try do
        [ Lazymaru.Validations,
          validator |> Atom.to_string |> Lazymaru.Utils.upper_camel_case
        ] |> Module.safe_concat
      rescue
        ArgumentError ->
          Lazymaru.Exceptions.UndefinedValidator |> raise [param: attr_name, validator: validator]
      end
    validator.validate_param!(attr_name, value, option)
    do_check_param(t, attr_name, value)
  end

end
