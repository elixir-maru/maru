defmodule Maru.Builder.Endpoint do
  @moduledoc """
  Generate endpoint of maru router.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator

  @doc """
  Generate general endpoint defined by user within method block.
  """
  def dispatch(ep, env, adapter) do
    pipeline =
      Enum.map(ep.plugs, fn p ->
        {p.plug, p.options, p.guards}
      end) |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    params_block = quote do
      var!(conn) = var!(conn) |> Plug.Conn.put_private(:maru_params,
        Maru.Builder.Endpoint.validate_params(
          unquote(ep.parameters |> Macro.escape),
          var!(conn).params,
          Maru.Builder.Path.parse_params(
            var!(conn).path_info,
            unquote(adapter.path_for_params(ep.path, ep.version))
          )
        )
      )
    end

    helpers =
      Enum.filter(ep.helpers, fn
        {:import, _, [module]} -> module != env.module
        _                      -> true
      end)

    quote do
      @file unquote(ep.__file__)

      defp unquote(adapter.func_name)(unquote(
        adapter.conn_for_match(ep.method, ep.version, ep.path)
      )=unquote(conn), []) do
        case unquote(body) do
          %Plug.Conn{halted: true} = conn ->
            conn
          %Plug.Conn{} = var!(conn) ->
            unquote(helpers)
            unquote(params_block)
            unquote(ep.block)
        end
      end
    end

  end

  @doc """
  Generate MethodNotAllow endpoint for all path without `match` method.
  """
  def dispatch_405(version, path, adapter) do
    method = Macro.var(:_, nil)

    quote do
      defp endpoint(unquote(
        adapter.conn_for_match(method, version, path)
      )=var!(conn), []) do
        Maru.Exceptions.MethodNotAllow |> raise([method: var!(conn).method, request_path: var!(conn).request_path])
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
          Maru.Exceptions.UndefinedValidator |> raise([param: attr_names, validator: action])
      end
    validator.validate!(attr_names, result)
    validate_params(t, params, result)
  end

  def validate_params([%Parameter{attr_name: attr_name, source: source, coerce_with: coercer, children: []}=p|t], params, result) do
    attr_value =
      pickup([
        result |> Map.get(attr_name),
        params |> Map.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer),
        p.default
      ])
    case {attr_value, p.required} do
      {nil, false} -> validate_params(t, params, result)
      {nil, true}  -> Maru.Exceptions.InvalidFormatter
                   |> raise([reason: :required, param: attr_name, option: p])
      {value, _}   ->
        value = check_param(attr_name, value, p)
        validate_params(t, params, put_in(result, [attr_name], value))
    end
  end

  def validate_params([%Parameter{attr_name: attr_name, source: source, coerce_with: coercer, children: children, parser: :map}=p|t], params, result) do
    nested_params = params |> Map.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise([reason: :required, param: attr_name, option: p])
      {true, false} ->
        validate_params(t, params, result)
      {false, _} ->
        value = validate_params(children, nested_params, %{})
        validate_params(t, params, put_in(result, [attr_name], value))
    end
  end

  def validate_params([%Parameter{attr_name: attr_name, source: source, coerce_with: coercer, children: children, parser: :list}=p|t], params, result) do
    nested_params = params |> Map.get(source || attr_name |> to_string) |> Maru.Coercer.parse(coercer)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise([reason: :required, param: attr_name, option: p])
      {true, false} ->
        validate_params(t, params, result)
      {false, _} ->
        value = nested_params |> Enum.map(&validate_params(children, &1, %{}))
        validate_params(t, params, put_in(result, [attr_name], value))
    end
  end


  defp pickup([e]), do: e
  defp pickup([h | t]) do
    if is_nil(h) do
      pickup(t)
    else
      h
    end
  end


  defp check_param(attr_name, value, parameters) do
    validators = parameters.validators
    value =
      try do
        Maru.ParamType.parse(value, parameters.parser)
      rescue
        ArgumentError ->
          Maru.Exceptions.InvalidFormatter |> raise([reason: :illegal, param: attr_name, value: value, option: validators])
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
          Maru.Exceptions.UndefinedValidator |> raise([param: attr_name, validator: validator])
      end
    validator.validate_param!(attr_name, value, option)
    do_check_param(t, attr_name, value)
  end

end
