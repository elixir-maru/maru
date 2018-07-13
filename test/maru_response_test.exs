defmodule Maru.ResponseTest do
  use ExUnit.Case, async: true
  import Plug.Test
  use Maru.Response

  test "redirect 302" do
    conn = conn(:get, "/") |> redirect("/foo")

    assert {"location", "/foo"} in conn.resp_headers
    assert 302 == conn.status
    assert conn.halted
  end

  test "redirect 301" do
    conn = conn(:get, "/") |> redirect("/bar", permanent: true)
    assert {"location", "/bar"} in conn.resp_headers
    assert 301 == conn.status
    assert conn.halted
  end

  test "redirect allow use of URI" do
    sample_uri = URI.parse("http://example.com/?foo=bar")
    conn = conn(:get, "/") |> redirect(sample_uri, permanent: true)
    assert {"location", "http://example.com/?foo=bar"} in conn.resp_headers
    assert 301 == conn.status
    assert conn.halted
  end

  test "conn in process dict" do
    put_maru_conn(1)
    assert 1 == get_maru_conn()
  end
end
