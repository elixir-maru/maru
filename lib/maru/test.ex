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
      import unquote(__MODULE__)

      defp make_response(conn, version \\ nil) do
        router = unquote(router)
        version = version || router.__version__
        conn
     |> Maru.Plugs.Prepare.call([])
     |> put_private(:maru_version, version)
     |> case do
          %Plug.Conn{params: %Plug.Conn.Unfetched{}}=c ->
            opts = [
              parsers: [
                Maru.Parsers.URLENCODED,
                Maru.Parsers.JSON,
                Plug.Parsers.MULTIPART,
              ],
              pass: ["*/*"],
              json_decoder: Poison
            ] |> Plug.Parsers.init
            Plug.Parsers.call(c, opts)
          c -> c
        end
     |> router.call([])
      end
    end
  end
end
