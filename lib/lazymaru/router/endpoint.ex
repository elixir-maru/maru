defmodule Lazymaru.Router.Endpoint do
  alias Lazymaru.Router.Param

  [ method: nil, path: [], desc: nil, param_context: [], block: nil, helpers: []
  ] |> defstruct

  def dispatch(ep) do
    path = ep.path |> Enum.map fn x when is_atom(x) -> Macro.var(:_, nil); x -> x end
    params_block = quote do
      var!(params) =
        Lazymaru.Router.Endpoint.validate_params(
          Enum.concat(var!(conn).private.lazymaru_param_context, unquote(ep.param_context |> Macro.escape)),
          var!(conn).params,
          Lazymaru.Router.Path.parse_params(
            var!(conn).path_info,
            var!(conn).private.lazymaru_route_path ++ unquote(ep.path)
          )
        )
    end

    quote do
      defp endpoint(%Plug.Conn{method: unquote(ep.method),
                               private: %{lazymaru_resource_path: unquote(path)}}=var!(conn), []) do
        unquote(params_block)
        unquote(ep.block)
      end
    end
  end


  def validate_params([], _params, result), do: result
  def validate_params([%Param{attr_name: attr_name, group: group, nested: false}=p|t], params, result) do
    attr_path = group ++ [attr_name]
    value =
      case { result[attr_name] || get_in(params, Enum.map(attr_path, &to_string/1)) || p.default, p.required } do
        {nil, false} -> nil
        {nil, true}  -> Lazymaru.Exceptions.InvalidFormatter
                     |> raise [reason: :required, param: attr_name, option: p]
        {value, _}   -> check_param(attr_name, value, p)
      end
    validate_params(t, params, put_in(result, attr_path, value))
  end

  def validate_params([%Param{attr_name: attr_name, group: group, parser: Lazymaru.ParamType.Map}=p|t], params, result) do
    attr_path = group ++ [attr_name]
    if is_nil(get_in params, Enum.map(attr_path, &to_string/1)) and p.required do
      Lazymaru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
    end
    result = put_in result, group ++ [attr_name], %{}
    validate_params(t, params, result)
  end

  def validate_params([%Param{attr_name: attr_name, group: group, parser: Lazymaru.ParamType.List}=p|t], params, result) do
    # TODO rails parser format
    attr_path = group ++ [attr_name]
    nested_params = get_in(params, Enum.map(attr_path, &to_string/1))
    if is_nil(nested_params) and p.required do
      Lazymaru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
    end
    {nested_param_context, rest} = split_param_context(t, attr_path)
    nested_result =
      for p <- nested_params do
        validate_params(nested_param_context, p, %{})
      end
    result = put_in result, attr_path, nested_result
    validate_params(rest, params, result)
  end

  defp split_param_context(list, group) do
    split_param_context(list, group, {[], []})
  end
  defp split_param_context([], _group, {left, right}), do: {Enum.reverse(left), Enum.reverse(right)}
  defp split_param_context([%Param{group: g}=p|t], group, {left, right}) do
    case lstrip(g, group) do
      nil          -> split_param_context(t, group, {left, [p | right]})
      {:ok, rest}  -> split_param_context(t, group, {[%{p | group: rest} | left], right})
    end
  end

  defp lstrip(rest, []),       do: {:ok, rest}
  defp lstrip([h|t1], [h|t2]), do: lstrip(t1, t2)
  defp lstrip(_, _),           do: nil


  defp check_param(attr_name, value, param_context) do
    parser = param_context.parser || Lazymaru.ParamType.Term
    validators = param_context.validators
    value = try do
        parser.from(value)
      rescue
        ArgumentError ->
          Lazymaru.Exceptions.InvalidFormatter |> raise [reason: :illegal, param: attr_name, value: value, option: validators]
      end
    do_check_param(validators, attr_name, value)
  end

  defp do_check_param([], _attr_name, value), do: value
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
