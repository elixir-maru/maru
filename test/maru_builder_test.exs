defmodule Maru.BuilderTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "method not allow with match" do
    defmodule MethodNotAllowWithMatchTest do
      use Maru.Builder

      get do
        text conn, "get"
      end

      match do
        text conn, "match"
      end

      def e(conn), do: endpoint(conn, [])
    end

    assert %Plug.Conn{resp_body: "get"} = conn(:get, "/") |> Maru.Plugs.Prepare.call([]) |> MethodNotAllowWithMatchTest.e
    assert %Plug.Conn{resp_body: "match"} = conn(:post, "/") |> Maru.Plugs.Prepare.call([]) |> MethodNotAllowWithMatchTest.e
  end


  test "method not allow without match" do
    defmodule MethodNotAllowWithoutMatchTest do
      use Maru.Builder

      get "path" do
        text conn, "get"
      end

      post ":var/path" do
        text conn, "post"
      end

      def e(conn), do: endpoint(conn, [])
    end

    assert %Plug.Conn{resp_body: "get"} = conn(:get, "/path") |> Maru.Plugs.Prepare.call([]) |> MethodNotAllowWithoutMatchTest.e
    assert_raise Maru.Exceptions.MethodNotAllow, fn ->
      conn(:post, "/path") |> Maru.Plugs.Prepare.call([]) |> MethodNotAllowWithoutMatchTest.e
    end
    assert_raise Maru.Exceptions.MethodNotAllow, fn ->
      conn(:get, "/var/path") |> Maru.Plugs.Prepare.call([]) |> MethodNotAllowWithoutMatchTest.e
    end
  end
end
