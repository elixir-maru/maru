defmodule Maru.Types.Charlist do
  @moduledoc """
  Buildin Type: Charlist
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_list(input), do: input

  def parse(input, _) do
    input |> to_charlist
  end
end
