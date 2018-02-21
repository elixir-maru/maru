defmodule Maru.Builder.Versioning.AcceptVersionHeader do
  @moduledoc """
  Adapter for accept-header versioning module.
  """

  use Maru.Builder.Versioning

  @doc false
  def get_version_plug(_opts) do
    [{Maru.Plugs.GetVersion, :accept_version_header, true}]
  end
end
