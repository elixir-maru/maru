defmodule Maru.Types.Map do
  use Maru.Type

  def parse(input, _) when is_map(input), do: input

end
