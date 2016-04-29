defmodule Maru.Coercions.Float do
  use Maru.Coercion

  def coerce(input, _) when is_float(input),   do: input
  def coerce(input, _) when is_integer(input), do: :erlang.float(input)
  def coerce(input, _) do
    input |> Elixir.Float.parse |> elem(0)
  end

  def value_coerced?(value) do
    is_float(value)
  end

end
