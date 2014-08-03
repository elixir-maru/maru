defmodule LazyHelper.ResponseTest do
  use ExUnit.Case, async: true
  import Plug.Test
  use LazyHelper.Response

  test "json response" do
    conn = conn(:get, "/")
    conn = [hello: :world] |> json
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == ~s({"hello":"world"})
  end

  test "html response" do
    conn = conn(:get, "/")
    conn = "<html>hello world<html>" |> html
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
    assert conn.resp_body == "<html>hello world<html>"
  end

  test "text response" do
    conn = conn(:get, "/")
    conn = "hello world" |> text
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
    assert conn.resp_body == "hello world"
  end

  test "header" do
    conn = conn(:get, "/", nil, headers: [{"foo", "bar"}])
    assert {"foo", "bar"} in headers
    header("baz", "foo")
    assert {"baz", "foo"} in conn.resp_headers
  end

  test "assign" do
    conn = conn(:get, "/")
    assign(:foo, "bar")
    assert assigns == %{foo: "bar"}
  end
end
