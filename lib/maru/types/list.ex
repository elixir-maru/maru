defmodule Maru.Types.List do
  @moduledoc """
  Buildin Type: List
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_list(input), do: input
end
