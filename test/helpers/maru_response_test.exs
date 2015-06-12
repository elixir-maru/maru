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
end
