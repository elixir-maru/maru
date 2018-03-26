defmodule Maru.Types.Json do
  @moduledoc """
  Buildin Type: Json
  """

  use Maru.Type

  @doc false
  def parse(input, _) do
    json_library = Maru.json_library()
    json_library.decode!(input)
  end
end
