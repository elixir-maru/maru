defmodule LazyHelper.Params do
  def parse_param(value, param, option) do
    try do
      Module.safe_concat(LazyParamType, option[:type]).from(value)
    rescue
      _ -> LazyException.InvalidFormatter
        |> raise [reason: :illegal, param: param, option: option]
    end |> check_param(param, option)
  end


  def check_param(value, param, option) do
    [ regexp: fn(x) -> Regex.match?(x, value |> to_string) end,
      range: fn(x) -> Enum.member?(x, value) end,
    ] |> check_param(value, param, option)
  end
  def check_param([], value, param, _), do: [{param, value}]
  def check_param([{k, f}|t], value, param, option) do
    if Dict.has_key?(option, k) and not f.(option[k]) do
      LazyException.InvalidFormatter |> raise [reason: :unformatted, param: param, option: option]
    end
    check_param(t, value, param, option)
  end


  defmacro requires(param, option) do
    quote do
      case var!(:conn).params[unquote(param) |> to_string] || unquote(option[:default]) do
        nil -> LazyException.InvalidFormatter
            |> raise [reason: :required, param: unquote(param), option: unquote(option)]
        v   -> var!(:params) = var!(:params)
            |> Dict.merge parse_param(v, unquote(param), unquote(option))
      end
    end
  end


  defmacro optional(param, option) do
    quote do
      case var!(:conn).params[unquote(param) |> to_string] || unquote(option[:default]) do
        nil -> nil
        v   -> var!(:params) = var!(:params)
            |> Dict.merge parse_param(v, unquote(param), unquote(option))
      end
    end
  end
end