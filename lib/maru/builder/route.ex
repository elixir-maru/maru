defmodule Maru.Builder.Route do
  @moduledoc """
  Generate routes of maru router.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator

  @doc """
  Generate general route defined by user within method block.
  """
  def dispatch(route, env, adapter) do
    pipeline =
      Enum.map(route.plugs, fn p ->
        {p.plug, p.options, p.guards}
      end) |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    helpers =
      Enum.filter(route.helpers, fn
        {:import, _, [module]} -> module != env.module
        _                      -> true
      end)

    result = quote do: %{}
    params = quote do
      Map.merge(
        var!(conn).params,
        Maru.Builder.Path.parse_params(
          var!(conn).path_info,
          unquote(adapter.path_for_params(route.path, route.version))
        )
      )
    end
    quoted_param = Enum.reduce(route.parameters, result, &quote_param(&1, &2, params))
    params_block = quote do
      var!(conn) =
        Plug.Conn.put_private(
          var!(conn),
          :maru_params,
          unquote(quoted_param)
        )
    end

    quote do
      defp route(unquote(
        adapter.conn_for_match(route.method, route.version, route.path)
      )=unquote(conn), []) do
        case unquote(body) do
          %Plug.Conn{halted: true} = conn ->
            conn
          %Plug.Conn{} = var!(conn) ->
            unquote(helpers)
            unquote(params_block)
            unquote(route.module).endpoint(var!(conn), unquote(route.func_id))
        end
      end
    end

  end

  @doc """
  Generate MethodNotAllow route for all path without `match` method.
  """
  def dispatch_405(version, path, adapter) do
    method = Macro.var(:_, nil)

    quote do
      defp route(unquote(
        adapter.conn_for_match(method, version, path)
      )=var!(conn), []) do
        Maru.Exceptions.MethodNotAllow |> raise([method: var!(conn).method, request_path: var!(conn).request_path])
      end
    end
  end


  @doc """
  This is a private function, DO NOT use it with your code. I just define it as a public
  function for unittest.
  """
  def quote_param(%Validator{validator: validator, attr_names: attr_names}, result, _params) do
    quote do
      unquote(validator).validate!(unquote(attr_names), unquote(result))
      unquote(result)
    end
  end

  def quote_param(%Parameter{attr_name: attr_name, source: source, nested: nested}=p, result, params) do
    param_key      = source || (attr_name |> to_string)
    nil_block      = nil_block(p, result)
    validate_block = validate_block(attr_name, p.validators)
    parser_block   = parser_block(attr_name, p.parsers)
    nested_block   = nested_block(nested, p.children)

    quote do
      unquote(params)
      |> Map.get(unquote(param_key))
      |> case do
        nil   -> unquote(nil_block)
        value ->
          value = value |> unquote(parser_block)
          value |> unquote(validate_block)
          value = value |> unquote(nested_block)
          put_in(unquote(result), [unquote(attr_name)], value)
      end
    end
  end


  defp nil_block(%Parameter{attr_name: attr_name, default: default, required: required}, result) do
    if is_nil(default) do
      if required do
        quote do
          Maru.Exceptions.InvalidFormatter |> raise([reason: :required, param: unquote(attr_name), value: nil])
        end
      else
        result
      end
    else
      quote do
        put_in(unquote(result), [unquote(attr_name)], unquote(default))
      end
    end
  end


  defp parser_block(attr_name, parsers) do
    value = quote do: value
    block =
      parsers
      |> Enum.map(fn
        {:func, func} ->
          quote do
            unquote(func).()
          end
        {:module, module, arguments} ->
          quote do
            unquote(module).parse(unquote(arguments))
          end
      end)
      |> Enum.reduce(value, fn parser, ast ->
        quote do
          unquote(ast) |> unquote(parser)
        end
      end)
    quote do
      fn unquote(value) ->
        try do
          unquote(block)
        rescue
          _ ->
            Maru.Exceptions.InvalidFormatter |> raise([reason: :illegal, param: unquote(attr_name), value: unquote(value)])
        end
      end.()
    end
  end


  defp validate_block(attr_name, validators) do
    value = quote do: validate_value
    block =
      for {validator, option} <- validators do
        quote do
          unquote(validator).validate_param!(
            unquote(attr_name),
            unquote(value),
            unquote(option)
          )
        end
      end
    quote do
      fn unquote(value) ->
        unquote(block)
        :ok
      end.()
    end
  end

  defp nested_block(nested, parameters) do
    result = quote do: %{}
    params = quote do: nested_params
    block = Enum.reduce(parameters, result, &quote_param(&1, &2, params))

    case nested do
      nil ->
        quote do
          fn x -> x end.()
        end
      :map ->
        quote do
          fn unquote(params) ->
            unquote(block)
          end.()
        end
      :list ->
        quote do
          fn x ->
            for unquote(params) <- x do
              unquote(block)
            end
          end.()
        end
    end
  end

end
