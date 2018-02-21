defmodule Maru.Types.File do
  @moduledoc """
  Buildin Type: File
  """

  use Maru.Type

  @doc false
  def parse(%Plug.Upload{} = input, _), do: input
end
