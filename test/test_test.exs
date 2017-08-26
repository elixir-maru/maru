defmodule Maru.TestTest do
  use ExUnit.Case, async: true

  test "test" do
    defmodule Test1 do
      use Maru.Router, make_plug: true

      get do
        text(conn, "resp")
      end
    end

    defmodule TestTest1 do
      use Maru.Test, root: Maru.TestTest.Test1

      def test do
        get("/") |> text_response
      end
    end

    assert "resp" = TestTest1.test
  end

  test "version test" do
    defmodule Test2 do
      use Maru.Router, versioning: [using: :param, parameter: "v"]

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
      use Maru.Test, root: Maru.TestTest.Test2

      def test1 do
        get("/?v=v1") |> text_response
      end

      def test2 do
        get("/?v=v2") |> text_response
      end

      def test3 do
        build_conn()
        |> put_body_or_params(%{v: "v1"})
        |> get("/")
        |> text_response
      end

      def test4 do
        build_conn()
        |> put_body_or_params(%{v: "v2"})
        |> get("/")
        |> text_response
      end
    end

    assert "resp v1" = TestTest2.test1
    assert "resp v2" = TestTest2.test2
    assert "resp v1" = TestTest2.test3
    assert "resp v2" = TestTest2.test4
  end

  test "parser test" do
    defmodule Test3 do
      use Maru.Router, make_plug: true

      plug Plug.Parsers, [
        parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.JSON, Plug.Parsers.MULTIPART],
        pass: ["*/*"],
        json_decoder: Poison
      ]

      params do
        requires :foo
      end
      post do
        json(conn, params)
      end
    end

    defmodule TestTest3 do
      use Maru.Test, root: Maru.TestTest.Test3

      def test do
        build_conn()
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> put_body_or_params(~s({"foo":"bar"}))
        |> post("/")
        |> json_response
      end
    end

    assert %{"foo" => "bar"} = TestTest3.test
  end

  test "mounted" do
    defmodule PlugTest do
      def init([]), do: []
      def call(conn, []) do
        conn |> Plug.Conn.put_private(:maru_plug_test, 0)
      end
    end

    defmodule PlugTest1 do
      def init([]), do: []
      def call(conn, []) do
        conn |> Plug.Conn.put_private(:maru_plug_test1, 0)
      end
    end

    defmodule TestMountShared do
      use Maru.Router

      get :shared do
        text(conn, "shared")
      end
    end

    defmodule TestMount1 do
      use Maru.Router

      plug Maru.TestTest.PlugTest1

      namespace :m1 do
        get do
          text(conn, "m1")
        end
        mount Maru.TestTest.TestMountShared
      end
    end

    defmodule TestMount2 do
      use Maru.Router

      namespace :m2 do
        get do
          text(conn, "m2")
        end
        mount Maru.TestTest.TestMountShared
      end
    end

    defmodule TestMount do
      use Maru.Router, make_plug: true

      plug Maru.TestTest.PlugTest

      mount Maru.TestTest.TestMount1
      mount Maru.TestTest.TestMount2
    end

    defmodule TestMountTest1 do
      use Maru.Test, root: Maru.TestTest.TestMount
      def test, do: get("/m1/shared")
    end

    defmodule TestMountTest2 do
      use Maru.Test, root: Maru.TestTest.TestMount
      def test, do: get("/m2/shared")
    end

    private1 = TestMountTest1.test().private
    assert 0 == private1.maru_plug_test
    assert 0 == private1.maru_plug_test1

    private2 = TestMountTest2.test().private
    assert 0 == private2.maru_plug_test
    assert false == Map.has_key?(private2, :maru_plug_test1)

  end

  test "mounted overridable" do
    defmodule PlugTest2 do
      def init([]), do: []
      def call(conn, []) do
        conn |> Plug.Conn.put_private(:maru_plug_test2, 0)
      end
    end

    defmodule PlugTest3 do
      def init([]), do: []
      def call(conn, []) do
        conn |> Plug.Conn.put_private(:maru_plug_test3, 0)
      end
    end

    defmodule MountedOverriableShared do
      use Maru.Router

      pipeline do
        plug_overridable :test, Maru.TestTest.PlugTest3
      end
      get :shared do
        text(conn, "shared")
      end
    end

    defmodule MountedOverriable do
      use Maru.Router, make_plug: true

      plug_overridable :test, Maru.TestTest.PlugTest2
      mount Maru.TestTest.MountedOverriableShared
    end

    defmodule MountedOverriableSharedTest do
      use Maru.Test, root: Maru.TestTest.MountedOverriable
      def test, do: get("shared")
    end

    private = MountedOverriableSharedTest.test().private
    assert 0 == private.maru_plug_test3
    assert false == Map.has_key?(private, :maru_plug_test2)
  end

  test "mounted with exception handlers" do
    defmodule MWEH.M2 do
      use Maru.Router

      rescue_from MatchError do
        conn |> put_status(502) |> text("502")
      end

      get do
        text(conn, "200")
      end

      get "match_error" do
        raise MatchError # 1 = 2
        text(conn, "200")
      end

      get "arithmetic_error" do
        raise ArithmeticError # 2 / 0
        text(conn, "200")
      end

      get "runtime_error" do
        raise "runtime_error"
        text(conn, "200")
      end
    end

    defmodule MWEH.M1 do
      use Maru.Router
      mount Maru.TestTest.MWEH.M2

      rescue_from ArithmeticError do
        conn |> put_status(501) |> text("501")
      end
    end

    defmodule MWEH do
      use Maru.Router, make_plug: true
      mount Maru.TestTest.MWEH.M1

      rescue_from :all do
        conn |> put_status(500) |> text("500")
      end
    end

    defmodule MWEH.M2.TEST do
      use Maru.Test, root: Maru.TestTest.MWEH

      def test1, do: get("/").status
      def test2, do: get("/match_error").status
      def test3, do: get("/arithmetic_error").status
      def test4, do: get("/runtime_error").status
    end

    assert 200 == MWEH.M2.TEST.test1
    assert 502 == MWEH.M2.TEST.test2
    assert 501 == MWEH.M2.TEST.test3
    assert 500 == MWEH.M2.TEST.test4
  end

end
