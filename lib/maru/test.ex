defmodule Maru.Test do
  defmacro __using__(opts) do
    router = Keyword.fetch! opts, :for
    quote do
      import Plug.Test
      import Plug.Conn
      import unquote(__MODULE__)

      defp make_response(conn) do
        router = unquote(router)
        version = router.__version__
        conn
     |> Maru.Plugs.Prepare.call([])
     |> put_private(:maru_version, version)
     |> router.call([])
      end
    end
  end
end
