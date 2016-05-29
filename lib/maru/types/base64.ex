defmodule Maru.Types.Base64 do
  use Maru.Type

  def parse(input, _) do
    input |> Base.decode64!
  end

end
