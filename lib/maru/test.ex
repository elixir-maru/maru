defmodule Maru.Test do
  @moduledoc """
  Unittest wrapper for designated router.
  """

  @doc false
  defmacro __using__(opts) do
    router = Keyword.fetch! opts, :for

    quote do
      import Plug.Test
      import Plug.Conn

      defp make_response(conn, version \\ nil) do
        router = unquote(router)
        version = version || router.__version__
        conn
        |> put_private(:maru_test, true)
        |> put_private(:maru_version, version)
        |> router.call([])
      end
    end

  end
end
