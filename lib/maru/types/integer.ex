defmodule Maru.Types.Integer do
  @moduledoc """
  Buildin Type: Integer
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_integer(input), do: input
  def parse(input, _) when is_binary(input), do: input |> String.to_integer()
  def parse(input, _) when is_list(input), do: input |> List.to_integer()

  def parse(input, _) do
    input |> to_string |> String.to_integer()
  end
end
