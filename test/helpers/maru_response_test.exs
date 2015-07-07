defmodule Maru.Helpers.ResponseTest do
  use ExUnit.Case, async: true
  import Plug.Test
  use Maru.Helpers.Response

  test "header" do
    conn = conn(:get, "/") |> put_req_header("foo", "bar")
    assert {"foo", "bar"} in headers
    header("baz", "foo")
    assert {"baz", "foo"} in conn.resp_headers
  end

  test "assign" do
    conn = conn(:get, "/")
    assign(:foo, "bar")
    assert assigns == %{foo: "bar"}
  end

  test "status int" do
    conn = conn(:post, "/")
    status 201
    assert 201 = conn.status
  end

  test "status atom" do
    conn = conn(:get, "/")
    status :ok
    assert 200 = conn.status
  end

  defmodule User do
    defstruct [:name, :age, :password]
  end

  defmodule UserEntity do
    def serialize(payload, %{}) do
      %{name: payload.name, age: payload.age}
    end
  end

  test "present/2" do
    conn = conn(:get, "/")
    user = %User{name: "falood", age: 25}
    present user, with: UserEntity
    assert %{ age: 25, name: "falood"
            } = conn.private[:maru_present]
  end

  test "present/3" do
    conn = conn(:get, "/")
    user1 = %User{name: "falood", age: 25}
    user2 = %User{name: "programiao", age: 23}
    present :user1, user1, with: UserEntity
    present :user2, user2, with: UserEntity
    assert %{ user1: %{age: 25, name: "falood"}, user2: %{age: 23, name: "programiao"}
            } = conn.private[:maru_present]
  end

  test "redirect 302" do
    conn = conn(:get, "/")
    redirect("/foo")

    assert {"location", "/foo"} in conn.resp_headers
    assert 302 == conn.status
  end

  test "redirect 301" do
    conn = conn(:get, "/")
    redirect("/bar", permanent: true)
    assert {"location", "/bar"} in conn.resp_headers
    assert 301 == conn.status
  end
end
