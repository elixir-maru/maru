defmodule Lazymaru.ValidationsTest do
  use ExUnit.Case , async: true
  alias Lazymaru.Validations

  test "regexp" do
    assert Validations.Regexp.validate_param!(:param, "1", ~r"1")
    assert_raise Lazymaru.Exceptions.Validation, fn ->
      Validations.Regexp.validate_param!(:param, "1", ~r"2")
    end
  end

  test "values" do
    assert Validations.Values.validate_param!(:param, 1, [1])
    assert Validations.Values.validate_param!(:param, 1, 1..10)
    assert_raise Lazymaru.Exceptions.Validation, fn ->
      Validations.Values.validate_param!(:param, 1, [])
    end
  end
end
