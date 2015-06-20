defmodule Maru.Router.EndpointTest do
  use ExUnit.Case, async: true
  import Plug.Test
  alias Maru.Router.Endpoint
  alias Maru.Router.Param
  alias Maru.Router.Validator

  test "validate param" do
    assert %{id: 1} == Endpoint.validate_params([%Param{attr_name: :id, parser: Maru.ParamType.Integer}], %{"id" => 1}, %{})
    assert_raise Maru.Exceptions.InvalidFormatter, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: Maru.ParamType.Integer}], %{"id" => "id"}, %{})
    end
    assert_raise Maru.Exceptions.Validation, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: Maru.ParamType.Integer, validators: [values: 1..10]}], %{"id" => "100"}, %{})
    end
  end

  test "identical param keys in groups" do
    assert %{group: %{name: "name1"}, name: "name2"} ==
      Endpoint.validate_params([
        %Param{attr_name: :name,  parser: Maru.ParamType.String, nested: false},
        %Param{attr_name: :group, parser: Maru.ParamType.Map,    nested: true},
        %Param{attr_name: :name,  parser: Maru.ParamType.String, group: [:group]}
      ], %{"group" => %{"name" => "name1"}, "name" => "name2"}, %{})
  end

  test "validate Map nested param" do
    assert %{group: %{name: "name"}} ==
      Endpoint.validate_params([ %Param{attr_name: :group, parser: Maru.ParamType.Map, nested: true},
                                 %Param{attr_name: :name, parser: Maru.ParamType.String, group: [:group]}
                               ], %{"group" => %{"name" => "name"}}, %{})
    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Maru.ParamType.Map, nested: true},
                                 %Param{attr_name: :group2, parser: Maru.ParamType.Map, nested: true, group: [:group]},
                                 %Param{attr_name: :name,   parser: Maru.ParamType.String, group: [:group, :group2]},
                                 %Param{attr_name: :name2,  parser: Maru.ParamType.String, group: [:group, :group2]},
                               ], %{"group" => %{"group2" => %{"name" => "name", "name2" => "name2"}}}, %{})
  end

  test "validate List nested param" do
    assert %{group: [%{foo: "foo1", bar: "default"}, %{foo: "foo2", bar: "bar"}]} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Maru.ParamType.List, nested: true},
                                 %Param{attr_name: :foo,    parser: Maru.ParamType.String, group: [:group]},
                                 %Param{attr_name: :bar,    parser: Maru.ParamType.String, group: [:group], default: "default"},
                                 %Validator{action: :at_least_one_of, attr_names: [:foo, :bar],  group: [:group]},
                               ], %{"group" => [%{"foo" => "foo1"}, %{"foo" => "foo2", "bar" => "bar"}]}, %{})
    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Maru.ParamType.List, nested: true},
                                 %Param{attr_name: :foo,    parser: Maru.ParamType.List, nested: true, group: [:group]},
                                 %Param{attr_name: :bar,    parser: Maru.ParamType.Map,  nested: true, group: [:group, :foo]},
                                 %Param{attr_name: :baz,    parser: Maru.ParamType.String, group: [:group, :foo, :bar]}
                               ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}, %{})
    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      Endpoint.validate_params([ %Param{attr_name: :group,  parser: Maru.ParamType.List, nested: true},
                                 %Param{attr_name: :foo,    parser: Maru.ParamType.List, nested: true, group: [:group]},
                                 %Param{attr_name: :bar,    parser: Maru.ParamType.Map,  nested: true, group: [:group, :foo]},
                                 %Param{attr_name: :baz,    parser: Maru.ParamType.String, group: [:group, :foo, :bar]},
                               ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}, %{})
  end

  test "validate optional nested param" do
    assert %{} ==
      Endpoint.validate_params([ %Param{attr_name: :group, parser: Maru.ParamType.List,   required: false, nested: true},
                                 %Param{attr_name: :foo,   parser: Maru.ParamType.String, required: true,  group: [:group]},
                               ], %{}, %{})
    assert %{} ==
      Endpoint.validate_params([ %Param{attr_name: :group, parser: Maru.ParamType.Map,    required: false, nested: true},
                                 %Param{attr_name: :foo,   parser: Maru.ParamType.String, required: true,  group: [:group]},
                               ], %{}, %{})
  end

  test "validate Action Validator" do
    assert %{group: %{foo: "foo"}} ==
      Endpoint.validate_params([ %Validator{action: :exactly_one_of, attr_names: [:foo, :bar, :baz],  group: [:group]}
                               ], %{}, %{group: %{foo: "foo"}})
    assert %{foo: "foo", bar: "bar"} ==
      Endpoint.validate_params([ %Validator{action: :at_least_one_of, attr_names: [:foo, :bar, :baz],  group: []}
                               ], %{}, %{foo: "foo", bar: "bar"})
    assert_raise Maru.Exceptions.Validation, fn ->
      Endpoint.validate_params([ %Validator{action: :mutually_exclusive, attr_names: [:foo, :bar, :baz],  group: []}
                               ], %{}, %{foo: "foo", bar: "bar"})
    end
  end

  test "send_resp status" do
    conn = %{conn(:get, "/") | status: 201}
    assert %Plug.Conn{status: 201, halted: true} = Endpoint.send_resp(conn, "")

    conn = conn(:post, "/")
    assert %Plug.Conn{status: 200, halted: true} = Endpoint.send_resp(conn, "")
  end

  test "send_resp content_type" do
    conn = conn(:get, "/") |> Plug.Conn.put_resp_content_type("application/json")
    assert {"content-type", "application/json; charset=utf-8"} in Endpoint.send_resp(conn, "").resp_headers

    conn = conn(:post, "/")
    assert {"content-type", "text/plain; charset=utf-8"} in Endpoint.send_resp(conn, "").resp_headers
  end
end
