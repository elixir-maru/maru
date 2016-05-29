defmodule Maru.TypesTest do
  use ExUnit.Case, async: true
  alias Maru.Types

  test "string" do
    assert Types.String.parse(1, %{})   == "1"
    assert Types.String.parse('1', %{}) == "1"
  end

  test "integer" do
    assert Types.Integer.parse('1', %{}) == 1
    assert Types.Integer.parse("1", %{}) == 1
  end

  test "float" do
    assert Types.Float.parse(1, %{})      == 1.0
    assert Types.Float.parse("1", %{})    == 1.0
    assert Types.Float.parse("1.0", %{})  == 1.0
    assert Types.Float.parse(-1, %{})     == -1.0
    assert Types.Float.parse("-1", %{})   == -1.0
    assert Types.Float.parse("-1.0", %{}) == -1.0
  end

  test "boolean" do
    assert Types.Boolean.parse(true, %{})    == true
    assert Types.Boolean.parse("true", %{})  == true
    assert Types.Boolean.parse(false, %{})   == false
    assert Types.Boolean.parse("false", %{}) == false
    assert Types.Boolean.parse(nil, %{})     == false
  end

  test "char list" do
    assert Types.CharList.parse(1, %{})   == '1'
    assert Types.CharList.parse("s", %{}) == 's'
  end

  test "atom" do
    assert_raise ArgumentError, fn ->
      Types.Atom.parse("never_exits_param", %{})
    end
    assert Types.Atom.parse("param", %{}) == :param
  end

  test "file" do
    f = %Plug.Upload{content_type: "image/jpeg", filename: "pic.jpg", path: "/tmp/pic.jpg"}
    assert Types.File.parse(f, %{}).__struct__ == Plug.Upload
  end

  test "list" do
    assert Types.List.parse([1, 2, 3], %{}) == [1, 2, 3]
  end

  test "map" do
    assert Types.Map.parse(%{a: 1}, %{}) == %{a: 1}
  end

  test "json" do
    assert Types.Json.parse(~s({"hello":"world"}), %{}) == %{"hello" => "world"}
  end

  test "base64" do
    assert Types.Base64.parse("eyJoZWxsbyI6IndvcmxkIn0=", %{}) == ~s({"hello":"world"})
  end


end
