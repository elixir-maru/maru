defmodule Maru.Types.String do
  use Maru.Type

  def parse(input, _) when is_binary(input), do: input
  def parse(input, _) do
    input |> to_string
  end

end
