defmodule Maru.Tasks.RoutesTest do
  use ExUnit.Case, async: true

  test "endpoint has no desc" do

    defmodule Router do
      use Maru.Router
      get do
        text(conn, "ok")
      end
    end

    defmodule API do
      use Maru.Router
      @test      false
      @make_plug true

      mount Maru.Tasks.RoutesTest.Router
    end
    route = API.__routes__ |> List.first
    assert "test: " <> (route.desc || "") == "test: "

  end

  test "endpoint has desc for summary" do

    defmodule Router2 do
      use Maru.Router

      desc "test endpoint" do
        get do
          text(conn, "ok")
        end
      end

    end

    defmodule API2 do
      use Maru.Router
      @test      false
      @make_plug true

      mount Maru.Tasks.RoutesTest.Router2
    end
    route = API2.__routes__ |> List.first
    assert_raise ArgumentError, "argument error", fn ->
      "test: " <> (route.desc || "")
    end
    assert "test: " <> (route.desc[:summary] || "") == "test: test endpoint"
  end

end
