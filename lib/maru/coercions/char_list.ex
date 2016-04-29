defmodule Maru.Coercions.CharList do
  use Maru.Coercion

  def coerce(input, _) when is_list(input), do: input
  def coerce(input, _) do
    input |> to_char_list
  end

  def value_coerced?(value) when is_list(value) do
    Enum.all?(value, &is_integer/1)
  end
  def value_coerced?(_), do: false

end
