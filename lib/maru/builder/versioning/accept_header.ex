defmodule Maru.Builder.Versioning.AcceptHeader do
  @moduledoc """
  Adapter for header versioning module.
  """

  use Maru.Builder.Versioning

  @doc false
  def get_version_plug(opts) do
    vendor = opts |> Keyword.fetch!(:vendor) |> to_string
    [{Maru.Plugs.GetVersion, {:accept_header, vendor}, true}]
  end
end
