defmodule Maru.ParamTypeTest do
  use ExUnit.Case, async: true
  alias Maru.ParamType

  test "term" do
    assert ParamType.Term.from([1, 2, 3]) == [1, 2, 3]
  end

  test "string" do
    assert ParamType.String.from(1)   == "1"
    assert ParamType.String.from('1') == "1"
  end

  test "integer" do
    assert ParamType.Integer.from('1') == 1
    assert ParamType.Integer.from("1") == 1
  end

  test "float" do
    assert ParamType.Float.from(1)     == 1.0
    assert ParamType.Float.from("1")   == 1.0
    assert ParamType.Float.from("1.0") == 1.0
  end

  test "boolean" do
    assert ParamType.Boolean.from(true)    == true
    assert ParamType.Boolean.from("true")  == true
    assert ParamType.Boolean.from(false)   == false
    assert ParamType.Boolean.from("false") == false
    assert ParamType.Boolean.from(nil)     == false
  end

  test "char list" do
    assert ParamType.CharList.from(1)   == '1'
    assert ParamType.CharList.from("s") == 's'
  end

  test "atom" do
    assert_raise ArgumentError, fn ->
      ParamType.Atom.from("never_exits_param")
    end
    assert ParamType.Atom.from("param") == :param
  end

  test "file" do
    f = %Plug.Upload{content_type: "image/jpeg", filename: "pic.jpg", path: "/tmp/pic.jpg"}
    assert ParamType.File.from(f).__struct__ == Plug.Upload
  end

  test "list" do
    assert ParamType.List.from([1, 2, 3]) == [1, 2, 3]
  end

  test "map" do
    assert ParamType.Map.from(%{a: 1}) == %{a: 1}
    assert_raise FunctionClauseError, fn ->
      ParamType.Map.from([a: 1]) == [a: 1]
    end
  end

  test "json" do
    assert ParamType.Json.from(~s({"hello":"world"})) == %{"hello" => "world"}
  end
end
