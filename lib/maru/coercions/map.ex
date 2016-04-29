defmodule Maru.Coercions.Map do
  use Maru.Coercion

  def value_coerced?(value) do
    is_map(value)
  end

end
