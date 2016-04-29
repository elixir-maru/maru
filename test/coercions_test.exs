defmodule Maru.CoercionsTest do
  use ExUnit.Case, async: true
  alias Maru.Coercions

  test "string" do
    assert Coercions.String.coerce(1, %{})   == "1"
    assert Coercions.String.coerce('1', %{}) == "1"
  end

  test "integer" do
    assert Coercions.Integer.coerce('1', %{}) == 1
    assert Coercions.Integer.coerce("1", %{}) == 1
  end

  test "float" do
    assert Coercions.Float.coerce(1, %{})      == 1.0
    assert Coercions.Float.coerce("1", %{})    == 1.0
    assert Coercions.Float.coerce("1.0", %{})  == 1.0
    assert Coercions.Float.coerce(-1, %{})     == -1.0
    assert Coercions.Float.coerce("-1", %{})   == -1.0
    assert Coercions.Float.coerce("-1.0", %{}) == -1.0
  end

  test "boolean" do
    assert Coercions.Boolean.coerce(true, %{})    == true
    assert Coercions.Boolean.coerce("true", %{})  == true
    assert Coercions.Boolean.coerce(false, %{})   == false
    assert Coercions.Boolean.coerce("false", %{}) == false
    assert Coercions.Boolean.coerce(nil, %{})     == false
  end

  test "char list" do
    assert Coercions.CharList.coerce(1, %{})   == '1'
    assert Coercions.CharList.coerce("s", %{}) == 's'
  end

  test "atom" do
    assert_raise ArgumentError, fn ->
      Coercions.Atom.coerce("never_exits_param", %{})
    end
    assert Coercions.Atom.coerce("param", %{}) == :param
  end

  test "file" do
    f = %Plug.Upload{content_type: "image/jpeg", filename: "pic.jpg", path: "/tmp/pic.jpg"}
    assert Coercions.File.coerce(f, %{}).__struct__ == Plug.Upload
  end

  test "list" do
    assert Coercions.List.coerce([1, 2, 3], %{}) == [1, 2, 3]
  end

  test "map" do
    assert Coercions.Map.coerce(%{a: 1}, %{}) == %{a: 1}
  end

  test "json" do
    assert Coercions.Json.coerce(~s({"hello":"world"}), %{}) == %{"hello" => "world"}
  end

  test "base64" do
    assert Coercions.Base64.coerce("eyJoZWxsbyI6IndvcmxkIn0=", %{}) == ~s({"hello":"world"})
  end


end
