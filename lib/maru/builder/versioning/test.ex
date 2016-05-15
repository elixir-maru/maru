defmodule Maru.Builder.Versioning.Test do
  @moduledoc """
  Adapter for generating test functions.
  """

  use Maru.Builder.Versioning

  @doc false
  def func_name do
    :route_test
  end

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
