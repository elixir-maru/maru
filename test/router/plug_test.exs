defmodule Lazymaru.Router.PlugTest do
  use ExUnit.Case , async: true

  test "parse_param" do
    assert [ id: 1 ] == Lazymaru.Router.Plug.parse_param("1", [parser: LazyParamType.Integer, param: :id])
    assert [ name: "name" ] == Lazymaru.Router.Plug.parse_param("name", [parser: LazyParamType.String, param: :name])
    assert_raise LazyException.InvalidFormatter, fn ->
      Lazymaru.Router.Plug.parse_param("id", [parser: LazyParamType.Integer, param: :id])
    end
    assert_raise LazyException.InvalidFormatter, fn ->
      Lazymaru.Router.Plug.parse_param(100, [parser: LazyParamType.Integer, param: :id, range: 1..10])
    end
  end
end
