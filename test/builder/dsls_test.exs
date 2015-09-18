defmodule Maru.Builder.DSLsTest do
  use ExUnit.Case, async: true
  alias Maru.Router.Resource

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
end
