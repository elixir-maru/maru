defmodule Maru.Runtime do
  @moduledoc false

  alias Maru.Struct.Parameter.Runtime, as: PR
  alias Maru.Struct.Validator.Runtime, as: VR

  @doc """
  parse params from `conn.params`.
  """
  def parse_params([], result, _), do: result
  def parse_params([%VR{validate_func: func} | t], result, conn_params) do
    func.(result)
    parse_params(t, result, conn_params)
  end
  def parse_params([%PR{attr_name: attr_name}=h | t], result, conn_params) do
    result =
      conn_params
      |> Map.get(h.param_key)
      |> case do
        nil   -> h.nil_func.(result)
        value ->
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
        Maru.Exceptions.InvalidFormatter
        |> raise([reason: :illegal, param: attr_name, value: value])
    end
  end


  defp do_nested(nil, _, value), do: value
  defp do_nested(:map, children, value) do
    parse_params(children, %{}, value)
  end
  defp do_nested(:list, children, value) do
    Enum.map(value, &parse_params(children, %{}, &1))
  end

end
