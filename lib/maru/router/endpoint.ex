defmodule Maru.Router.Endpoint do
  alias Maru.Router.Param
  alias Maru.Router.Validator

  [ method: nil, path: [], desc: nil, param_context: [], block: nil, helpers: []
  ] |> defstruct

  def dispatch(ep) do
    path = ep.path |> Enum.map fn x when is_atom(x) -> Macro.var(:_, nil); x -> x end
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
      defp endpoint(%Plug.Conn{method: unquote(ep.method),
                               private: %{maru_resource_path: unquote(path)}}=var!(conn), []) do
        unquote(params_block)
        resp = unquote(ep.block)
        Maru.Router.Endpoint.send_resp(var!(conn), resp)
      end
    end
  end


  def validate_params([], _params, result), do: result

  def validate_params([%Validator{action: action, attr_names: attr_names, group: group}|t], params, result) do
    validator =
      try do
        [ Maru.Validations,
          action |> Atom.to_string |> Maru.Utils.upper_camel_case
        ] |> Module.safe_concat
      rescue
        ArgumentError ->
          Maru.Exceptions.UndefinedValidator |> raise [param: attr_names, validator: action]
      end
    params_for_check =
      case group do
        [] -> result
        _  -> get_in(result, group)
      end
    validator.validate!(attr_names, params_for_check)
    validate_params(t, params, result)
  end

  def validate_params([%Param{attr_name: attr_name, group: group, nested: false}=p|t], params, result) do
    attr_path = group ++ [attr_name]
    value =
      case { get_in(result, attr_path) || get_in(params, Enum.map(attr_path, &to_string/1)) || p.default, p.required } do
        {nil, false} -> nil
        {nil, true}  -> Maru.Exceptions.InvalidFormatter
                     |> raise [reason: :required, param: attr_name, option: p]
        {value, _}   -> check_param(attr_name, value, p)
      end
    validate_params(t, params, put_in(result, attr_path, value))
  end

  def validate_params([%Param{attr_name: attr_name, group: group, parser: Maru.ParamType.Map}=p|t], params, result) do
    attr_path = group ++ [attr_name]
    nested_params = get_in(params, Enum.map(attr_path, &to_string/1))
    {_, rest} = split_param_context(t, attr_path)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
      {true, false} ->
        validate_params(rest, params, result)
      {false, _} ->
        validate_params(t, params, put_in(result, attr_path, %{}))
    end
  end

  def validate_params([%Param{attr_name: attr_name, group: group, parser: Maru.ParamType.List}=p|t], params, result) do
    # TODO rails parser format
    attr_path = group ++ [attr_name]
    nested_params = get_in(params, Enum.map(attr_path, &to_string/1))
    {nested_param_context, rest} = split_param_context(t, attr_path)
    case {is_nil(nested_params), p.required} do
      {true, true} ->
        Maru.Exceptions.InvalidFormatter |> raise [reason: :required, param: attr_name, option: p]
      {true, false} ->
        validate_params(rest, params, result)
      {false, _} ->
        nested_result = nested_params |> Enum.map &validate_params(nested_param_context, &1, %{})
        validate_params(rest, params, put_in(result, attr_path, nested_result))
    end
  end

  defp split_param_context(list, group) do
    split_param_context(list, group, {[], []})
  end
  defp split_param_context([], _group, {left, right}), do: {Enum.reverse(left), Enum.reverse(right)}
  defp split_param_context([p|t], group, {left, right}) do
    case lstrip(p.group, group) do
      nil          -> split_param_context(t, group, {left, [p | right]})
      {:ok, rest}  -> split_param_context(t, group, {[%{p | group: rest} | left], right})
    end
  end

  defp lstrip(rest, []),       do: {:ok, rest}
  defp lstrip([h|t1], [h|t2]), do: lstrip(t1, t2)
  defp lstrip(_, _),           do: nil


  defp check_param(attr_name, value, param_context) do
    parser = param_context.parser || Maru.ParamType.Term
    validators = param_context.validators
    value = try do
        parser.from(value)
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


  def send_resp(_, %Plug.Conn{private: %{maru_present: present}}=conn) do
    send_resp(conn, present)
  end

  def send_resp(_, %Plug.Conn{}=conn) do
    conn
  end

  def send_resp(conn, resp) do
    status = conn.status || 200
    body = resp |> Maru.Response.resp_body
    if Plug.Conn.get_resp_header(conn, "content-type") == [] do
      content_type = resp |> Maru.Response.content_type
      conn |> Plug.Conn.put_resp_content_type(content_type)
    else conn end
 |> Plug.Conn.send_resp(status, body)
 |> Plug.Conn.halt
  end

end
