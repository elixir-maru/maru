defmodule Maru.Types.Base64 do
  @moduledoc """
  Buildin Type: Base64
  """

  use Maru.Type

  @doc false
  def parse(input, _) do
    input |> Base.decode64!()
  end
end
