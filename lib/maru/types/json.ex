defmodule Maru.Types.Json do
  use Maru.Type

  def parse(input, _) do
    input |> Poison.decode!
  end

end
