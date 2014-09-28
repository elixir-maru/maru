defmodule Lazymaru.UtilsTest do
  use ExUnit.Case, async: true

  test "upper_camel_case" do
    assert "AB"   == Lazymaru.Utils.upper_camel_case "a_b"
    assert "AaBb" == Lazymaru.Utils.upper_camel_case "aa_Bb"
    assert "Ab"   == Lazymaru.Utils.upper_camel_case "ab"
  end
end
