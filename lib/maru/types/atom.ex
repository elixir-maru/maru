defmodule Maru.Types.Atom do
  @moduledoc """
  Buildin Type: Atom
  """

  use Maru.Type

  @doc false
  def parse(input, _) when is_atom(input), do: input

  def parse(input, _) do
    input |> to_string |> String.to_existing_atom()
  end
end
