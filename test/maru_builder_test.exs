defmodule Maru.BuilderTest do
  use ExUnit.Case, async: true
  import Plug.Test
  alias Maru.Router.Resource

  test "methods" do
    defmodule MethodsTest do
      use Maru.Builder

      get do
        "get"
      end

      match do
        "match"
      end

      def e, do: @endpoints |> Code.eval_quoted |> elem(0)
    end

    assert [
      %{method: {:_, [], nil}, path: []},
      %{method: "GET", path: []},
    ] = MethodsTest.e
  end

  test "prefix" do
    defmodule PrefixTest1 do
      use Maru.Builder
      prefix :foo

      def r, do: @resource
    end

    defmodule PrefixTest2 do
      use Maru.Builder
      prefix "foo/:bar"

      def r, do: @resource
    end

    defmodule PrefixTest3 do
      use Maru.Router
      prefix :foo

      namespace :bar do
        prefix :baz

        def r, do: @resource
      end
    end

    assert %Resource{path: ["foo"]} = PrefixTest1.r
    assert %Resource{path: ["foo", :bar]} = PrefixTest2.r
    assert %Resource{path: ["foo", "bar", "baz"]} = PrefixTest3.r
  end

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
