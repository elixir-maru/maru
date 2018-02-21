defmodule Maru.Types.String do
  @moduledoc """
  Buildin Type: Type
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_binary(input), do: input

  def parse(input, _) do
    input |> to_string
  end
end
