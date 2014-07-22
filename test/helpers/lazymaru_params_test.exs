defmodule LazyHelper.ParamsTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import LazyHelper.Params

  def ignore_unused(_), do: :ok

  def parse(conn, parser \\ []) do
    Plug.Parsers.call(conn, [parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART | parser], limit: 80_000_000])
  end

  test "url params" do
    params = %{}
    conn = parse(conn(:get, "/?foo0=1&bar1=baz"))
    requires :foo0, type: :integer
    requires :foo1, type: :integer, default: 2
    optional :bar0, type: :string, regexp: ~r/^[a-z]+$/
    optional :bar1, type: :string, regexp: ~r/^[a-z]+$/
    assert params == %{bar1: "baz", foo0: 1, foo1: 2}
  end

  test "body params" do
    params = %{}
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    conn = parse(conn(:get, "/", "foo0=1&bar1=baz", headers: headers))
    requires :foo0, type: :integer
    requires :foo1, type: :integer, default: 2
    optional :bar0, type: :string, regexp: ~r/^[a-z]+$/
    optional :bar1, type: :string, regexp: ~r/^[a-z]+$/
    assert params == %{bar1: "baz", foo0: 1, foo1: 2}
  end

  test "raise required" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/"))
      requires :foo, [type: :integer]
      ignore_unused params
    end
    assert exception.reason == :required
  end

  test "raise illegal" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/?foo=a"))
      requires :foo, [type: :integer]
      ignore_unused params
    end
    assert exception.reason == :illegal
  end

  test "raise unformatted" do
    exception = assert_raise LazyException.InvalidFormatter, fn ->
      params = %{}
      conn = parse(conn(:get, "/?foo=0"))
      requires :foo, [type: :string, regexp: ~r/^[a-z]+$/]
      ignore_unused params
    end
    assert exception.reason == :unformatted
  end

  test "custom params parser" do
    defmodule CustomParser do
      def parse(conn, "application", "xml", _headers, _opts) do
        {:ok, %{"foo" => "bar"}, conn}
      end

      def parse(conn, _type, _subtype, _headers, _opts) do
        {:next, conn}
      end
    end

    params = %{}
    headers = [{"content-type", "application/xml"}]
    conn = parse(conn(:post, "/", "", headers: headers), [CustomParser])
    requires :foo, type: :string, regexp: ~r/^[a-z]+$/
    assert params == %{foo: "bar"}
  end


  defmodule Baz do
    def from("baz"), do: :yup
    def from(_), do: :nope
  end

  test "custom types" do
    params = %{}
    conn = parse(conn(:get, "/?foo0=1&bar1=baz&bar2=biz"))
    requires :foo0, type: :integer
    requires :foo1, type: :integer, default: 2
    requires :bar1, type: Baz
    requires :bar2, type: Baz
    assert params == %{bar2: :nope, bar1: :yup, foo0: 1, foo1: 2}
  end
end
