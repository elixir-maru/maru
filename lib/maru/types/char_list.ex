defmodule Maru.Types.CharList do
  @moduledoc """
  Buildin Type: CharList
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_list(input), do: input
  def parse(input, _) do
    input |> to_char_list
  end

end
