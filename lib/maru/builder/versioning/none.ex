defmodule Maru.Builder.Versioning.None do
  @moduledoc """
  Adapter for no versioning module.
  """

  use Maru.Builder.Versioning

  @doc false
  def conn_for_match(method, _, path) do
    quote do
      %Plug.Conn{
        method: unquote(method),
        path_info: unquote(path_for_match(path)),
      }
    end
  end

end
