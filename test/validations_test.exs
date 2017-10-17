defmodule Maru.ValidationsTest do
  use ExUnit.Case, async: true
  alias Maru.Validations

  test "regexp" do
    assert Validations.Regexp.validate_param!(:param, "1", ~r"1")
    assert Validations.Regexp.validate_param!(:param, ["1", "12", "31"], ~r"1")
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.Regexp.validate_param!(:param, "1", ~r"2")
    end
  end

  test "values" do
    assert Validations.Values.validate_param!(:param, 1, [1])
    assert Validations.Values.validate_param!(:param, 1, 1..10)
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.Values.validate_param!(:param, 1, [])
    end
  end

  test "allow_blank" do
    assert Validations.AllowBlank.validate_param!(:param, nil, true)
    assert Validations.AllowBlank.validate_param!(:param, '',  true)
    assert Validations.AllowBlank.validate_param!(:param, "",  true)
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.AllowBlank.validate_param!(:param, nil, false)
    end
  end

  test "mutually_exclusive" do
    assert Validations.MutuallyExclusive.validate!([:a, :b], %{a: 1})
    assert Validations.MutuallyExclusive.validate!([:a, :b], %{b: 1})
    assert Validations.MutuallyExclusive.validate!([:a, :b], %{})
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.MutuallyExclusive.validate!([:a, :b], %{a: 1, b: 2})
    end
  end

  test "exactly_one_of" do
    assert Validations.ExactlyOneOf.validate!([:a, :b], %{a: 1})
    assert Validations.ExactlyOneOf.validate!([:a, :b], %{b: 1})
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.ExactlyOneOf.validate!([:a, :b], %{})
    end
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.ExactlyOneOf.validate!([:a, :b], %{a: 1, b: 2})
    end
  end

  test "at_least_one_of" do
    assert Validations.AtLeastOneOf.validate!([:a, :b], %{a: 1})
    assert Validations.AtLeastOneOf.validate!([:a, :b], %{b: 1})
    assert Validations.AtLeastOneOf.validate!([:a, :b], %{a: 1, b: 2})
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.AtLeastOneOf.validate!([:a, :b], %{})
    end
  end

  test "all_or_none_of" do
    assert Validations.AllOrNoneOf.validate!([:a, :b], %{})
    assert Validations.AllOrNoneOf.validate!([:a, :b], %{a: 1, b: 2})
    assert_raise Maru.Exceptions.Validation, fn ->
      Validations.AllOrNoneOf.validate!([:a, :b], %{a: 1})
    end
  end
end
