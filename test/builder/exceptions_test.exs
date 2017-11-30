defmodule Maru.Builder.ExceptionsTest do
  use ExUnit.Case, async: true
  import Plug.Test


  test "rescue_from" do
    defmodule RescueTest do
      use Maru.Router, make_plug: true

      defp unwarn(_), do: nil

      get :test1 do
        [] = conn
      end

      get :test2 do
        unwarn(conn)
        List.first %{}
      end

      get :test3 do
        unwarn(conn)
        raise "err"
      end

      rescue_from MatchError do
        conn
        |> put_status(500)
        |> text("match error")
      end

      rescue_from [UndefinedFunctionError, FunctionClauseError] do
        conn
        |> put_status(500)
        |> text("function error")
      end

      rescue_from Maru.Exceptions.MethodNotAllowed, with: :err405

      rescue_from :all, as: e do
        conn
        |> put_status(500)
        |> text(e.message)
      end

      defp err405(conn, _exception) do
        conn
        |> put_status(405)
        |> text("MethodNotAllowed")
      end

    end

    conn1 = conn(:get, "test1")
    assert %Plug.Conn{resp_body: "match error", status: 500} = RescueTest.call(conn1, [])

    conn2 = conn(:get, "test2")
    assert %Plug.Conn{resp_body: "function error", status: 500} = RescueTest.call(conn2, [])

    conn3 = conn(:get, "test3")
    assert %Plug.Conn{resp_body: "err", status: 500} = RescueTest.call(conn3, [])

    conn4 = conn(:post, "test3")
    assert %Plug.Conn{resp_body: "MethodNotAllowed", status: 405} = RescueTest.call(conn4, [])
  end

  test "conn in process dict" do
    defmodule RescueWithConnTest do
      use Maru.Router, make_plug: true

      defp unwarn(_), do: nil

      Application.put_env(:maru, Maru.Builder.ExceptionsTest.RescueWithConnTest,
        versioning: [
          using: :param,
          parameter: "v",
        ]
      )

      version "v1"

      before do
        plug Plug.Parsers,
          pass: ["*/*"],
          json_decoder: Poison,
          parsers: [:urlencoded, :json, :multipart]
      end

      params do
        requires :a
      end

      get "/a" do
        unwarn(params)
        text(conn, "a")
      end

      params do
        requires :b
      end
      get "/b" do
        unwarn(conn)
        unwarn(params)
        raise "b"
      end

      rescue_from :all do
        conn
        |> put_status(500)
        |> text("c")
      end

    end

    conn1 = conn(:get, "a?b=1&v=v1")
    assert %Plug.Conn{
      resp_body: "c",
      private: %{maru_version: "v1"}
    } = RescueWithConnTest.call(conn1, [])

    conn2 = conn(:get, "b?b=1&v=v1")
    assert %Plug.Conn{
      resp_body: "c",
      private: %{
        maru_version: "v1",
        maru_params:  %{b: "1"},
      },
    } = RescueWithConnTest.call(conn2, [])
  end

  test "mounted routes" do
    defmodule MountedRoutesTest.Mounted do
      use Maru.Router, make_plug: true

      defp unwarn(_), do: nil

      get :test1 do
        [] = conn
      end

      get :test2 do
        unwarn(conn)
        raise "err"
      end

      rescue_from [MatchError], with: :err500

      defp err500(conn, _exception) do
        conn
        |> put_status(500)
        |> text("match error")
      end
    end

    defmodule MountedRoutesTest do
      use Maru.Router, make_plug: true

      mount Maru.Builder.ExceptionsTest.MountedRoutesTest.Mounted

      rescue_from :all, as: e do
        conn
        |> put_status(501)
        |> text(e.message)
      end
    end

    defmodule MountedRoutes2Test do
      use Maru.Router, make_plug: true

      mount Maru.Builder.ExceptionsTest.MountedRoutesTest.Mounted
    end

    conn1 = conn(:get, "test1")
    assert %Plug.Conn{resp_body: "match error", status: 500} = MountedRoutesTest.call(conn1, [])

    conn2 = conn(:get, "test2")
    assert %Plug.Conn{resp_body: "err", status: 501} = MountedRoutesTest.call(conn2, [])

    conn3 = conn(:get, "test1")
    assert %Plug.Conn{resp_body: "match error", status: 500} = MountedRoutes2Test.call(conn3, [])
  end

  test "plug router exceptions" do
    defmodule PlugRouterExceptionTest do
      use Maru.Router, make_plug: true

      get do
        text(conn, "hello")
      end
    end

    conn1 = conn(:get, "/not_found")
    assert_raise Maru.Exceptions.NotFound, fn ->
     PlugRouterExceptionTest.call(conn1, [])
    end

    defmodule HandlePlugRouterExceptionTest do
      use Maru.Router, make_plug: true

      get do
        text(conn, "hello")
      end

      rescue_from :all do
        conn |> put_status(404) |> text("not found")
      end
    end

    conn2 = conn(:get, "/not_found")
    assert %Plug.Conn{status: 404} =
      HandlePlugRouterExceptionTest.call(conn2, [])
  end

end
