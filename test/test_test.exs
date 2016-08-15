defmodule Maru.TestTest do
  use ExUnit.Case, async: true

  test "test" do
    defmodule Test1 do
      use Maru.Router
      version "v3"

      get do
        text(conn, "resp")
      end
    end

    defmodule TestTest1 do
      use Maru.Test, for: Test1

      def test do
        get("/") |> text_response
      end
    end

    assert "resp" = TestTest1.test
  end

  test "version test" do
    defmodule Test2 do
      use Maru.Router

      version "v1" do
        get do
          text(conn, "resp v1")
        end
      end

      version "v2" do
        get do
          text(conn, "resp v2")
        end
      end
    end

    defmodule TestTest2 do
      use Maru.Test, for: Test2

      def test1 do
        get("/", "v1") |> text_response
      end

      def test2 do
        get("/", "v2") |> text_response
      end
    end

    assert "resp v1" = TestTest2.test1
    assert "resp v2" = TestTest2.test2
  end

  test "parser test" do
    defmodule Test3 do
      use Maru.Router

      params do
        requires :foo
      end
      post do
        json(conn, params)
      end
    end

    defmodule TestTest3 do
      use Maru.Test, for: Test3

      def test do
        opts = [
          parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.JSON, Plug.Parsers.MULTIPART],
          pass: ["*/*"],
          json_decoder: Poison
        ]

        build_conn()
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> put_body_or_params(~s({"foo":"bar"}))
        |> put_plug(Plug.Parsers, opts)
        |> post("/")
        |> json_response
      end
    end

    assert %{"foo" => "bar"} = TestTest3.test
  end

end
