defmodule Maru.Builder.MethodsTest do
  use ExUnit.Case, async: true

  test "methods" do
    defmodule MethodsTest do
      use Maru.Builder

      get do
        "get"
      end

      match do
        "match"
      end

      def e, do: @endpoints
    end

    assert [
      %{method: {:_, [], nil}, path: []},
      %{method: "GET", path: []},
    ] = MethodsTest.e
  end
end
