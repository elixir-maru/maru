defmodule Maru.Helpers.ResponseTest do
  use ExUnit.Case, async: true
  import Plug.Test
  use Maru.Helpers.Response

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

end
