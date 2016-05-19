defmodule Maru.Builder.Versioning.Test do
  @moduledoc """
  Adapter for generating test functions.
  """
  use Maru.Builder.Versioning

  @doc false
  def plug(_opts), do: []

  @doc false
  def conn_for_match(method, version, path) do
    quote do
      %Plug.Conn{
        method: unquote(method),
        path_info: unquote(path_for_match(path)),
        private: %{
          maru_test:    true,
          maru_version: unquote(version),
        }
      }
    end
  end

end
