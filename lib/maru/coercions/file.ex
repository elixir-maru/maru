defmodule Maru.Coercions.File do
  use Maru.Coercion

  def value_coerced?(%Plug.Upload{}), do: true
  def value_coerced?(_),              do: false

end
