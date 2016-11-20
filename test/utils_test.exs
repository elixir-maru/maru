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

  test "make_validator" do
    assert_raise Maru.Exceptions.UndefinedValidator, fn ->
      make_validator(:a)
    end

    defmodule Elixir.Maru.Validations.V do
    end

    assert Elixir.Maru.Validations.V = make_validator(:v)
  end

  test "make_type" do
    type = quote do: A
    assert_raise Maru.Exceptions.UndefinedType, fn ->
      make_type(type)
    end

    defmodule Elixir.Maru.Types.B do
      use Elixir.Maru.Type
    end
    type = quote do: B
    assert Elixir.Maru.Types.B = make_type(type)
  end

  test "split router" do
    router = quote do A |> B |> Maru.Type end
    assert [A, B, Maru.Type] = split_router(router)

    router = quote do: A
    assert [A] = split_router(router)
  end
end
