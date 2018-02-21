defmodule Maru.UtilsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Maru.Utils

  test "upper_camel_case" do
    assert "AB" == upper_camel_case("a_b")
    assert "AaBb" == upper_camel_case("aa_Bb")
    assert "Ab" == upper_camel_case("ab")
  end

  test "lower_underscore" do
    assert "a_b" == lower_underscore("AB")
    assert "aa_bb" == lower_underscore("AaBb")
    assert "ab" == lower_underscore("Ab")
  end

  test "make_validator" do
    assert_raise Maru.Exceptions.UndefinedValidator, fn ->
      make_validator(:a)
    end

    defmodule Elixir.Maru.Validations.V do
    end

    assert Elixir.Maru.Validations.V = make_validator(:v)
  end

  test "make_type" do
    assert_raise Maru.Exceptions.UndefinedType, fn ->
      make_type(A)
    end

    defmodule Elixir.Maru.Types.B do
      use Elixir.Maru.Type
    end

    assert Elixir.Maru.Types.B = make_type(B)
  end

  test "warning unknown opts" do
    assert capture_io(:stderr, fn ->
             Maru.Utils.warning_unknown_opts(A, [:a, :b, :c])
           end) =~ "unknown `use` options :a, :b, :c for module A"
  end
end
