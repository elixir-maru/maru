defmodule Maru.TestTest do
  use ExUnit.Case, async: true

  test "test" do
    defmodule Test do
      use Maru.Router

      get do: "resp"
    end

    defmodule TestTest do
      use Maru.Test, for: Test

      def test do
        conn(:get, "/") |> make_response
      end
    end

    assert %Plug.Conn{resp_body: "resp"} = TestTest.test
  end
end
