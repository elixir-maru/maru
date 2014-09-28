defmodule Lazymaru.Router.EndpointTest do
  use ExUnit.Case , async: true
  alias Lazymaru.Router.Endpoint

  test "parse_param" do
    assert %{ id: 1 } == Endpoint.parse_params([id: [parser: Lazymaru.ParamType.Integer]], %{"id" => 1})
    assert %{ name: "name" } == Endpoint.parse_params([name: [parser: Lazymaru.ParamType.String]], %{"name" => "name"})
    assert_raise Lazymaru.Exceptions.InvalidFormatter, fn ->
      Endpoint.parse_params([id: [parser: Lazymaru.ParamType.Integer]], %{"id" => "id"})
    end
    assert_raise Lazymaru.Exceptions.Validation, fn ->
      Endpoint.parse_params([id: [parser: Lazymaru.ParamType.Integer, validators: [values: 1..10]]], %{"id" => "100"})
    end
  end
end
