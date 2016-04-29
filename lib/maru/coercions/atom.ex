defmodule Maru.Coercions.Atom do
  use Maru.Coercion

  def coerce(input, _) when is_atom(input), do: input
  def coerce(input, _) do
    input |> to_string |> String.to_existing_atom
  end

  def value_coerced?(value) do
    is_atom(value)
  end

end
