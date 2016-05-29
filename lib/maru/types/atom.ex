defmodule Maru.Types.Atom do
  use Maru.Type

  def parse(input, _) when is_atom(input), do: input
  def parse(input, _) do
    input |> to_string |> String.to_existing_atom
  end

end
