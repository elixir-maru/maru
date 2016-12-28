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

      defmacro test_user do
        quote do
          "test_user"
        end
      end
    end

    defmodule TestRouter do
      use Maru.Router

      helpers Maru.HelperTest.TestHelper

      get "/" do
        text(conn, test_user)
      end
    end

    defmodule Test1 do
      use Maru.Test, for: Maru.HelperTest.TestRouter

      def test do
        get("/") |> text_response
      end
    end

    assert "test_user" = Test1.test
  end
end
