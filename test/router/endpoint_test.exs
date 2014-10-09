defmodule Lazymaru.Router.EndpointTest do
  use ExUnit.Case , async: true
  alias Lazymaru.Router.Endpoint
  alias Lazymaru.Router.Param

  test "validate param" do
    assert %{id: 1} == Endpoint.validate_params([%Param{attr_name: :id, parser: Lazymaru.ParamType.Integer}], %{"id" => 1}, %{})
    assert_raise Lazymaru.Exceptions.InvalidFormatter, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: Lazymaru.ParamType.Integer}], %{"id" => "id"}, %{})
    end
    assert_raise Lazymaru.Exceptions.Validation, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: Lazymaru.ParamType.Integer, validators: [values: 1..10]}], %{"id" => "100"}, %{})
    end
  end

  test "validate Map nested param" do
    assert %{group: %{name: "name"}} ==
      Endpoint.validate_params([ %Param{attr_name: :group, parser: Lazymaru.ParamType.Map, nested: true},
                                 %Param{attr_name: :name, parser: Lazymaru.ParamType.String, group: [:group]}
                               ], %{"group" => %{"name" => "name"}}, %{})
    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Lazymaru.ParamType.Map, nested: true},
                                 %Param{attr_name: :group2, parser: Lazymaru.ParamType.Map, nested: true, group: [:group]},
                                 %Param{attr_name: :name,   parser: Lazymaru.ParamType.String, group: [:group, :group2]},
                                 %Param{attr_name: :name2,  parser: Lazymaru.ParamType.String, group: [:group, :group2]},
                               ], %{"group" => %{"group2" => %{"name" => "name", "name2" => "name2"}}}, %{})
  end

  test "validate List nested param" do
    assert %{group: [%{foo: "foo1", bar: "default"}, %{foo: "foo2", bar: "bar"}]} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Lazymaru.ParamType.List, nested: true},
                                 %Param{attr_name: :foo,    parser: Lazymaru.ParamType.String, group: [:group]},
                                 %Param{attr_name: :bar,    parser: Lazymaru.ParamType.String, group: [:group], default: "default"},
                               ], %{"group" => [%{"foo" => "foo1"}, %{"foo" => "foo2", "bar" => "bar"}]}, %{})
    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Lazymaru.ParamType.List, nested: true},
                                 %Param{attr_name: :foo,    parser: Lazymaru.ParamType.List, nested: true, group: [:group]},
                                 %Param{attr_name: :bar,    parser: Lazymaru.ParamType.Map,  nested: true, group: [:group, :foo]},
                                 %Param{attr_name: :baz,    parser: Lazymaru.ParamType.String, group: [:group, :foo, :bar]}
                               ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}, %{})
  end
end
