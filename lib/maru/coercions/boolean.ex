defmodule Maru.Coercions.Boolean do
  use Maru.Coercion

  def coerce(true, _),    do: true
  def coerce("true", _),  do: true
  def coerce(nil, _),     do: false
  def coerce(false, _),   do: false
  def coerce("false", _), do: false


  def value_coerced?(value) do
    is_boolean(value)
  end

end
