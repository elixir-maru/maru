defmodule LazyParamTypeTest do
  use ExUnit.Case, async: true

  test "string" do
    assert LazyParamType.String.from(1) == "1"
    assert LazyParamType.String.from('1') == "1"
  end

  test "integer" do
    assert LazyParamType.Integer.from('1') == 1
    assert LazyParamType.Integer.from("1") == 1
  end

  test "float" do
    assert LazyParamType.Float.from(1) == 1.0
    assert LazyParamType.Float.from("1") == 1.0
    assert LazyParamType.Float.from("1.0") == 1.0
  end

  test "boolean" do
    assert LazyParamType.Boolean.from(true) == true
    assert LazyParamType.Boolean.from("true") == true
    assert LazyParamType.Boolean.from(false) == false
    assert LazyParamType.Boolean.from("false") == false
    assert LazyParamType.Boolean.from(nil) == false
  end

  test "char list" do
    assert LazyParamType.CharList.from(1) == '1'
    assert LazyParamType.CharList.from("s") == 's'
  end

  test "atom" do
    assert LazyParamType.Atom.from(:param) == :param
    assert LazyParamType.Atom.from("param") == :param
  end

  test "file" do
    f = %Plug.Upload{content_type: "image/jpeg", filename: "pic.jpg", path: "/tmp/pic.jpg"}
    assert LazyParamType.File.from(f).__struct__ == Plug.Upload
  end
end
