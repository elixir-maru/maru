defmodule Maru.Coercions.Base64 do
  use Maru.Coercion

  def coerce(input, _) do
    input |> Base.decode64!
  end

end
