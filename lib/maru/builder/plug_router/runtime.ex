alias Maru.Builder.PlugRouter

defmodule PlugRouter.Runtime do
  @moduledoc false

  alias Maru.Builder.Parameter
  alias Parameter.Runtime, as: PR
  alias Parameter.Dependent.Runtime, as: DR
  alias Parameter.Validator.Runtime, as: VR

  @doc """
  parse params from `conn.params`.
  """
  def parse_params([], result, _), do: result

  def parse_params([%VR{validate_func: func} | t], result, conn_params) do
    func.(result)
    parse_params(t, result, conn_params)
  end

  def parse_params([%DR{validators: validators} = h | t], result, conn_params) do
    addition = (Enum.all?(validators, fn func -> func.(result) end) && h.children) || []
    parse_params(addition ++ t, result, conn_params)
  end

  def parse_params([%PR{attr_name: attr_name} = h | t], result, conn_params) do
    passed? = conn_params |> Map.has_key?(h.param_key)
    value = conn_params |> Map.get(h.param_key)

    result =
      if Maru.Utils.is_blank(value) do
        h.blank_func.({value, passed?, result})
      else
        value = do_parse(h.parser_func, value, attr_name)
        h.validate_func.(value)
        value = do_nested(h.nested, h.children, value)
        put_in(result, [h.attr_name], value)
      end

    parse_params(t, result, conn_params)
  end

  defp do_parse(func, value, attr_name) do
    try do
      func.(value)
    rescue
      _ ->
        Maru.Exceptions.InvalidFormat
        |> raise(reason: :illegal, param: attr_name, value: value)
    end
  end

  defp do_nested(nil, _, value), do: value

  defp do_nested(:map, [], value), do: value

  defp do_nested(:map, children, value) do
    parse_params(children, %{}, value)
  end

  defp do_nested(:list, [], value), do: value

  defp do_nested(:list, children, value) do
    Enum.map(value, &parse_params(children, %{}, &1))
  end

  @doc """
  parse path params
  """
  def parse_path_params(conn_path_info, route_path) do
    do_parse_path_params(conn_path_info, route_path, %{})
  end

  defp do_parse_path_params([], [], result), do: result

  defp do_parse_path_params([h | t1], [h | t2], result) do
    do_parse_path_params(t1, t2, result)
  end

  defp do_parse_path_params([h1 | t1], [h2 | t2], result) when is_atom(h2) do
    do_parse_path_params(t1, t2, put_in(result, [to_string(h2)], h1))
  end
end
