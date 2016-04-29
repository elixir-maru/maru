defmodule Maru.Coercions.Integer do
  use Maru.Coercion

  def coerce(input, _) when is_binary(input), do: input |> String.to_integer
  def coerce(input, _) when is_list(input),   do: input |> List.to_integer
  def coerce(input, _) do
    input |> to_string |> String.to_integer
  end

  def value_coerced?(value) do
    is_integer(value)
  end

end
