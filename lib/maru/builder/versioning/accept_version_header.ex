defmodule Maru.Builder.Versioning.AcceptVersionHeader do
  @moduledoc """
  Adapter for accept-header versioning module.
  """

  use Maru.Builder.Versioning

  @doc false
  def plug(_opts) do
    [{Maru.Plugs.Version, :accept_version_header, true}]
  end

end
