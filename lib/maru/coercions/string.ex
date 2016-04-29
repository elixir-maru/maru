defmodule Maru.Coercions.String do
  use Maru.Coercion

  def coerce(input, _) when is_binary(input), do: input
  def coerce(input, _) do
    input |> to_string
  end

  def value_coerced?(value) do
    is_binary(value)
  end

end
