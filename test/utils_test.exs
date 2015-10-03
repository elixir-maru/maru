defmodule Maru.UtilsTest do
  use ExUnit.Case, async: true
  import Maru.Utils

  test "upper_camel_case" do
    assert "AB"   == upper_camel_case "a_b"
    assert "AaBb" == upper_camel_case "aa_Bb"
    assert "Ab"   == upper_camel_case "ab"
  end

  test "lower_underscore" do
    assert "a_b"   == lower_underscore "AB"
    assert "aa_bb" == lower_underscore "AaBb"
    assert "ab"    == lower_underscore "Ab"
  end
end
