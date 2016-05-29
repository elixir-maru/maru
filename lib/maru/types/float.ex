defmodule Maru.Types.Float do
  use Maru.Type

  def parse(input, _) when is_float(input),   do: input
  def parse(input, _) when is_integer(input), do: :erlang.float(input)
  def parse(input, _) do
    input |> Elixir.Float.parse |> elem(0)
  end

end
