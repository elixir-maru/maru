defmodule Maru.Types.List do
  use Maru.Type

  def parse(input, _) when is_list(input), do: input

end
