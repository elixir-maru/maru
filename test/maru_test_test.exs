defmodule Maru.TestTest do
  use ExUnit.Case, async: true

  test "test" do
    defmodule Test1 do
      use Maru.Router
      version "v3"

      get do: "resp"
    end

    defmodule TestTest1 do
      use Maru.Test, for: Test1

      def test do
        conn(:get, "/") |> make_response
      end
    end

    assert %Plug.Conn{resp_body: "resp"} = TestTest1.test
  end

  test "version test" do
    defmodule Test2 do
      use Maru.Router

      version "v1" do
        get do: "resp v1"
      end

      version "v2" do
        get do: "resp v2"
      end
    end

    defmodule TestTest2 do
      use Maru.Test, for: Test2

      def test1 do
        conn(:get, "/") |> make_response("v1")
      end

      def test2 do
        conn(:get, "/") |> make_response("v2")
      end
    end

    assert %Plug.Conn{resp_body: "resp v1"} = TestTest2.test1
    assert %Plug.Conn{resp_body: "resp v2"} = TestTest2.test2
  end

  test "parser test" do
    defmodule Test3 do
      use Maru.Router

      params do
        requires :foo
      end
      post do
        params
      end
    end

    defmodule TestTest3 do
      use Maru.Test, for: Test3

      def test do
        conn(:post, "/", ~s({"foo":"bar"}))
     |> Plug.Conn.put_req_header("content-type", "application/json")
     |> make_response
      end
    end

    assert %Plug.Conn{resp_body: ~s({"foo":"bar"})} = TestTest3.test
  end
end
