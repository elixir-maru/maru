defmodule Maru.Types.Map do
  @moduledoc """
  Buildin Type: Map
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_map(input), do: input
end
