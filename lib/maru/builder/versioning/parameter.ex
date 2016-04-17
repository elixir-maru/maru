defmodule Maru.Builder.Versioning.Parameter do
  @moduledoc """
  Adapter for parameter versioning module.
  """
  use Maru.Builder.Versioning

  @doc false
  def plug(opts) do
    key = opts |> Keyword.get(:parameter, :apiver) |> to_string
    [{Maru.Plugs.Version, {:parameter, key}, true}]
  end

end
