defmodule Maru.MiddlewareTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "middleware" do
    defmodule Before do
      use Maru.Middleware

      def call(conn, _opts) do
        assign(:user_id, 1)
        conn
      end
    end

    defmodule Router do
      use Maru.Router

      get do
        params
        "ok"
      end
    end

    defmodule API do
      use Maru.Router

      plug Maru.MiddlewareTest.Before
      mount Maru.MiddlewareTest.Router
    end

    assert %Plug.Conn{assigns: %{user_id: 1}} = conn(:get, "/") |> Maru.MiddlewareTest.API.call([])
  end
end
