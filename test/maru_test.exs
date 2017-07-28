defmodule MaruTest do
  use ExUnit.Case, async: true

  describe "maru application test" do
    Application.put_env(:maru, MaruTest.MaruRouter, [])
    Application.put_env(:maru, MaruTest.NoThisModule, [])
    Application.put_env(:maru, MaruTest.NotMaruRouter, [])

    defmodule MaruRouter do
      use Maru.Router, make_plug: true
    end

    defmodule NotMaruRouter do
    end

    test "correct maru router" do
      assert Enum.any?(Maru.servers, fn {MaruRouter, _} -> true; _ -> false end)
    end

    test "module not defined" do
      refute  Enum.any?(Maru.servers, fn {NoThisModule, _} -> true; _ -> false end)
    end

    test "module is not a maru router" do
      refute  Enum.any?(Maru.servers, fn {NotMaruRouter, _} -> true; _ -> false end)
    end
  end
end
