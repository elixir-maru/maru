defmodule Lazymaru.UtilsTest do
  use ExUnit.Case, async: true
  import Lazymaru.Utils

  test "upper_camel_case" do
    assert "AB"   == upper_camel_case "a_b"
    assert "AaBb" == upper_camel_case "aa_Bb"
    assert "Ab"   == upper_camel_case "ab"
  end
end
