defmodule Maru.Types.File do
  use Maru.Type

  def parse(%Plug.Upload{}=input, _), do: input

end
