defmodule Maru.Types.CharList do
  use Maru.Type

  def parse(input, _) when is_list(input), do: input
  def parse(input, _) do
    input |> to_char_list
  end

end
