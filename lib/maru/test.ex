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
        case conn do
          %Plug.Conn{params: %Plug.Conn.Unfetched{}}=c ->
            c |> Plug.Parsers.call([parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Poison])
          c -> c
        end
     |> Maru.Plugs.Prepare.call([])
     |> put_private(:maru_version, version)
     |> router.call([])
      end
    end
  end
end
