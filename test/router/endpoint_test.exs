defmodule Lazymaru.Router.EndpointTest do
  use ExUnit.Case , async: true
  alias Lazymaru.Router.Endpoint

  test "parse_param" do
    assert %{ id: 1 } == Endpoint.parse_params([id: [parser: LazyParamType.Integer]], %{"id" => 1})
    assert %{ name: "name" } == Endpoint.parse_params([name: [parser: LazyParamType.String]], %{"name" => "name"})
    assert_raise LazyException.InvalidFormatter, fn ->
      Endpoint.parse_params([id: [parser: LazyParamType.Integer]], %{"id" => "id"})
    end
    assert_raise LazyException.InvalidFormatter, fn ->
      Endpoint.parse_params([id: [parser: LazyParamType.Integer, validators: [range: 1..10]]], %{"id" => "100"})
    end
  end
end
