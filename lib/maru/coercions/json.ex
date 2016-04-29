defmodule Maru.Coercions.Json do
  use Maru.Coercion

  def coerce(input, _) do
    input |> Poison.decode!
  end

end
