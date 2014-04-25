defmodule LazyHelper.ResponseTest do
  use ExUnit.Case, async: true
  import Plug.Test
  use LazyHelper.Response

  def ignore_unused(_), do: :ok

  test "json response" do
    conn = conn(:get, "/")
    conn = [hello: :world] |> json
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ~s({"hello":"world"})
  end

  test "html response" do
    conn = conn(:get, "/")
    conn = "<html>hello world<html>" |> html
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "<html>hello world<html>"
  end

  test "text response" do
    conn = conn(:get, "/")
    conn = "hello world" |> text
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "hello world"
  end
end
