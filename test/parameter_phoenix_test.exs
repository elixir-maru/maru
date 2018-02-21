defmodule Maru.Parameter.PhoenixTest do
  use ExUnit.Case, async: true

  test "params DSL for phoenix" do
    defmodule Controller do
      use Maru.Parameter.Phoenix

      params do
        requires :foo, type: Integer

        optional :bar, type: List do
          optional :baz
        end
      end

      def index(_conn, params) do
        params
      end

      params do
        optional :bar, type: Integer

        optional :baz, type: Map do
          optional :foo
        end

        mutually_exclusive [:bar, :baz]
      end

      def create(_conn, params) do
        params
      end
    end

    assert %{bar: [%{baz: "3"}], foo: 1} =
             Controller.index([], %{"foo" => "1", "bar" => [%{"baz" => 3}]})

    assert %{baz: %{foo: "2"}} = Controller.create([], %{"baz" => %{"foo" => 2}})

    assert_raise Maru.Exceptions.Validation, fn ->
      Controller.create([], %{"bar" => 1, "baz" => %{"foo" => 2}})
    end
  end
end
