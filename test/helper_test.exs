defmodule Maru.HelperTest do
  use ExUnit.Case, async: true

  test "shared params" do
    defmodule Test do
      use Maru.Helper

      params :foo do
        requests :bar, type: String
      end
    end

    assert [foo: {:requests, _, [:bar, _]}] = Test.__shared_params__
  end

  test "helpers methods" do
    defmodule TestHelper do
      use Maru.Helper

      defmacro test_user1 do
        quote do
          "test_user1"
        end
      end

      defmacro set_test_user2 do
        quote do
          var!(conn) = var!(conn) |> assign(:test_user2, "test_user2")
        end
      end
    end

    defmodule TestRouter do
      use Maru.Router

      helpers Maru.HelperTest.TestHelper

      get "/test1" do
        text(conn, test_user1())
      end

      get "/test2" do
        set_test_user2()
        text(conn, conn.assigns[:test_user2])
      end
    end

    defmodule Test1 do
      use Maru.Test, for: Maru.HelperTest.TestRouter

      def test1 do
        get("/test1") |> text_response
      end

      def test2 do
        get("/test2") |> text_response
      end
    end

    assert "test_user1" = Test1.test1
    assert "test_user2" = Test1.test2
  end
end
