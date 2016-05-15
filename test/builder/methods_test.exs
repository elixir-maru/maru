defmodule Maru.Builder.MethodsTest do
  use ExUnit.Case, async: true

  test "methods" do
    defmodule MethodsTest do
      use Maru.Builder

      get do
        text(conn, "get")
      end

      match do
        text(conn, "match")
      end

      def route, do: @routes
    end

    assert [
      %{method: {:_, [], nil}, path: []},
      %{method: "GET", path: []},
    ] = MethodsTest.route
  end

end
