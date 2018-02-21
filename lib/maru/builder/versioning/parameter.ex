defmodule Maru.Builder.Versioning.Parameter do
  @moduledoc """
  Adapter for parameter versioning module.
  """

  use Maru.Builder.Versioning

  @doc false
  def get_version_plug(opts) do
    key = opts |> Keyword.get(:parameter, :apiver) |> to_string
    [{Maru.Plugs.GetVersion, {:parameter, key}, true}]
  end
end
