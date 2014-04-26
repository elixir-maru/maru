defmodule LazyHelper.ParamsTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import LazyHelper.Params

  def ignore_unused(_), do: :ok

  def parse(conn) do
    Plug.Parsers.call(conn, [parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART], limit: 80_000_000])
  end

  test "url params" do
    params = %{}
    conn = parse(conn(:get, "/?foo0=1&bar1=baz"))
    requires :foo0, type: Integer
    requires :foo1, type: Integer, default: 2
    optional :bar0, type: String, regexp: ~r/^[a-z]+$/
    optional :bar1, type: String, regexp: ~r/^[a-z]+$/
    assert params == %{bar1: "baz", foo0: 1, foo1: 2}
  end

  test "body params" do
    params = %{}
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    conn = parse(conn(:get, "/", "foo0=1&bar1=baz", headers: headers))
    requires :foo0, type: Integer
    requires :foo1, type: Integer, default: 2
    optional :bar0, type: String, regexp: ~r/^[a-z]+$/
    optional :bar1, type: String, regexp: ~r/^[a-z]+$/
    assert params == %{bar1: "baz", foo0: 1, foo1: 2}
  end

  test "raise required" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/"))
      requires :foo, [type: Integer]
      ignore_unused params
    end
    assert exception.reason == :required
  end

  test "raise illegal" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/?foo=a"))
      requires :foo, [type: Integer]
      ignore_unused params
    end
    assert exception.reason == :illegal
  end

  test "raise unformatted" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/?foo=0"))
      requires :foo, [type: String, regexp: ~r/^[a-z]+$/]
      ignore_unused params
    end
    assert exception.reason == :unformatted
  end
end
