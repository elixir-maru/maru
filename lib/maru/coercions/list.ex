defmodule Maru.Coercions.List do
  use Maru.Coercion

  def value_coerced?(value) do
    is_list(value)
  end

end
