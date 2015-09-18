defmodule Maru.Builder.ExceptionsTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "rescue_from" do
    defmodule RescueTest do
      use Maru.Router

      get :test1 do
        [] = conn
      end

      get :test2 do
        List.first %{}
      end

      get :test3 do
        raise Maru.Exceptions.NotFound, method: "GET"
      end

      rescue_from MatchError do
        status 500
        "match error"
      end

      rescue_from [UndefinedFunctionError, FunctionClauseError] do
        status 500
        "function error"
      end

      rescue_from :all, as: e do
        status 500
        e.method
      end
    end

    conn1 = conn(:get, "test1")
    assert %Plug.Conn{resp_body: "match error", status: 500} = RescueTest.call(conn1, [])

    conn2 = conn(:get, "test2")
    assert %Plug.Conn{resp_body: "function error", status: 500} = RescueTest.call(conn2, [])

    conn3 = conn(:get, "test3")
    assert %Plug.Conn{resp_body: "GET", status: 500} = RescueTest.call(conn3, [])
  end
end
