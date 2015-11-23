defmodule Maru.Router.Endpoint do
  @moduledoc """
  Generate endpoint of maru router.
  """

  alias Maru.Router.Param
  alias Maru.Router.Validator

  [ method: nil, path: [], version: nil, desc: nil, param_context: [], block: nil, helpers: []
  ] |> defstruct

  @doc """
  Generate general endpoint defined by user within method block.
  """
  def dispatch(ep) do
    path = ep.path |> Enum.map fn x when is_atom(x) -> Macro.var(:_, nil); x -> x end
    version =
      case ep.version do
        nil -> Macro.var(:_, nil)
        v   -> v
      end
    params_block = quote do
      var!(conn) = var!(conn) |> Plug.Conn.put_private(:maru_params,
        Maru.Router.Endpoint.validate_params(
          Enum.concat(var!(conn).private.maru_param_context, unquote(ep.param_context |> Macro.escape)),
          var!(conn).params,
          Maru.Router.Path.parse_params(
            var!(conn).path_info,
            var!(conn).private.maru_route_path ++ unquote(ep.path)
          )
        )
      )
    end

    quote do
      defp endpoint(%Plug.Conn{
        method: unquote(ep.method),
        private: %{
          maru_resource_path: unquote(path),
          maru_version: unquote(version),
        }
      }=var!(conn), []) do
        unquote(params_block)
        unquote(ep.block)
      end
    end
  end


  @doc """
  Generate MethodNotAllow endpoint for all path without `match` method.
  """
  def dispatch_405(version, path) do
    method = Macro.var(:_, nil)
    path = path |> Enum.map fn x when is_atom(x) -> Macro.var(:_, nil); x -> x end
    version =
      case version do
        nil -> Macro.var(:_, nil)
        v   -> v
      end

    quote do
      defp endpoint(%Plug.Conn{
        method: unquote(method),
        private: %{
          maru_resource_path: unquote(path),
          maru_version: unquote(version),
        }
      }=var!(conn), []) do
        Maru.Exceptions.MethodNotAllow |> raise [method: var!(conn).method, request_path: var!(conn).request_path]
      end
    end
  end


  @doc """
  Parse and validate params.
  """
  def validate_params([], _params, result), do: result

  def validate_params([%Validator{action: action, attr_names: attr_names}|t], params, result) do
    validator =
      try do
        [ Maru.Validations,
          action |> Atom.to_string |> Maru.Utils.upper_camel_case
        ] |> Module.safe_concat
      rescue
        ArgumentError ->
          Maru.Exceptions.UndefinedValidator |> raise [param: attr_names, validator: action]
      end
    validator.validate!(attr_names, result)
    validate_params(t, params, result)
  end

  def validate_params([%Param{attr_name: attr_name, source: source, coerce_with: coercer, children: []}=p|t], params, result) do
    attr_value =
      result |> Dict.get(attr_name) ||
      params |> Dict.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer) ||
      p.default
    value =
      case {attr_value, p.required} do
        {nil, false} -> nil
        {nil, true}  -> Maru.Exceptions.InvalidFormatter
                     |> raise [reason: :required, param: attr_name, option: p]
        {value, _}   -> check_param(attr_name, value, p)
      end
    validate_params(t, params, put_in(result, [attr_name], value))
  end

  def validate_params([%Param{attr_name: attr_name, source: source, coerce_with: coercer, children: children, parser: :map}=p|t], params, result) do
    nested_params = params |> Dict.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
      {true, false} ->
        validate_params(t, params, result)
      {false, _} ->
        value = validate_params(children, nested_params, %{})
        validate_params(t, params, put_in(result, [attr_name], value))
    end
  end

  def validate_params([%Param{attr_name: attr_name, source: source, coerce_with: coercer, children: children, parser: :list}=p|t], params, result) do
    nested_params = params |> Dict.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
      {true, false} ->
        validate_params(t, params, result)
      {false, _} ->
        value = nested_params |> Enum.map &validate_params(children, &1, %{})
        validate_params(t, params, put_in(result, [attr_name], value))
    end
  end


  defp check_param(attr_name, value, param_context) do
    validators = param_context.validators
    value =
      try do
        Maru.ParamType.parse(value, param_context.parser)
      rescue
        ArgumentError ->
          Maru.Exceptions.InvalidFormatter |> raise [reason: :illegal, param: attr_name, value: value, option: validators]
      end
    do_check_param(validators, attr_name, value)
  end

  defp do_check_param([], _attr_name, value), do: value
  defp do_check_param([{validator, option}|t], attr_name, value) do
    validator = try do
        [ Maru.Validations,
          validator |> Atom.to_string |> Maru.Utils.upper_camel_case
        ] |> Module.safe_concat
      rescue
        ArgumentError ->
          Maru.Exceptions.UndefinedValidator |> raise [param: attr_name, validator: validator]
      end
    validator.validate_param!(attr_name, value, option)
    do_check_param(t, attr_name, value)
  end

end
