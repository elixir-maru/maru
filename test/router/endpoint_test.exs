defmodule Maru.Router.EndpointTest do
  use ExUnit.Case, async: true
  import Plug.Test
  alias Maru.Router.Endpoint
  alias Maru.Router.Param
  alias Maru.Router.Validator

  test "validate param" do
    assert %{id: 1} == Endpoint.validate_params([%Param{attr_name: :id, parser: :integer}], %{"id" => 1}, %{})
    assert_raise Maru.Exceptions.InvalidFormatter, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: :integer}], %{"id" => "id"}, %{})
    end
    assert_raise Maru.Exceptions.Validation, fn ->
      Endpoint.validate_params([%Param{attr_name: :id, parser: :integer, validators: [values: 1..10]}], %{"id" => "100"}, %{})
    end
  end

  test "identical param keys in groups" do
    assert %{group: %{name: "name1"}, name: "name2"} ==
      Endpoint.validate_params([
        %Param{attr_name: :name, parser: :string},
        %Param{attr_name: :group, parser: :map, children: [
          %Param{attr_name: :name, parser: :string}
        ]}
      ], %{"group" => %{"name" => "name1"}, "name" => "name2"}, %{})
  end

  test "validate Map nested param" do
    assert %{group: %{name: "name"}} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, children: [
          %Param{attr_name: :name, parser: :string}
        ]}
      ], %{"group" => %{"name" => "name"}}, %{})

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, children: [
          %Param{attr_name: :group2, parser: :map, children: [
            %Param{attr_name: :name, parser: :string},
            %Param{attr_name: :name2, parser: :string},
          ]}
        ]}
      ], %{"group" => %{"group2" => %{"name" => "name", "name2" => "name2"}}}, %{})
  end

  test "validate List nested param" do
    assert %{group: [%{foo: "foo1", bar: "default"}, %{foo: "foo2", bar: "bar"}]} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :list, children: [
          %Param{attr_name: :foo, parser: :string},
          %Param{attr_name: :bar, parser: :string, default: "default"},
          %Validator{action: :at_least_one_of, attr_names: [:foo, :bar]},
        ]}
      ], %{"group" => [%{"foo" => "foo1"}, %{"foo" => "foo2", "bar" => "bar"}]}, %{})

    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :list, children: [
          %Param{attr_name: :foo, parser: :list, children: [
            %Param{attr_name: :bar, parser: :map, children: [
              %Param{attr_name: :baz, parser: :string}
            ]}
          ]}
        ]}
      ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}, %{})

    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :list, children: [
          %Param{attr_name: :foo, parser: :list, children: [
            %Param{attr_name: :bar, parser: :map, children: [
              %Param{attr_name: :baz, parser: :string}
            ]}
          ]}
        ]}
      ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}, %{})
  end

  test "validate Json nested param" do
    assert %{group: %{name: "name"}} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, coerce_with: :json, children: [
          %Param{attr_name: :name, parser: :string}
        ]}
      ], %{"group" => ~s({"name":"name"})}, %{})

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, children: [
          %Param{attr_name: :group2, parser: :map, coerce_with: :json, children: [
            %Param{attr_name: :name, parser: :string},
            %Param{attr_name: :name2, parser: :string},
          ]}
        ]}
      ], %{"group" => %{"group2" => ~s({"name2":"name2","name":"name"})}}, %{})
  end

  test "param rename" do
    assert %{group: %{name: "name"}} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, coerce_with: :json, children: [
          %Param{attr_name: :name, source: "name-test", parser: :string}
        ]}
      ], %{"group" => ~s({"name-test":"name"})}, %{})
  end

  test "validate optional nested param" do
    assert %{} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :list, required: false, children: [
          %Param{attr_name: :foo, parser: :string, required: true},
        ]}
      ], %{}, %{})

    assert %{} ==
      Endpoint.validate_params([
        %Param{attr_name: :group, parser: :map, required: false, children: [
          %Param{attr_name: :foo,   parser: :string, required: true}
        ]}
      ], %{}, %{})
  end

  test "validate Action Validator" do
    assert %{foo: "foo"} ==
      Endpoint.validate_params([
        %Validator{action: :exactly_one_of, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo"})

    assert %{foo: "foo", bar: "bar"} ==
      Endpoint.validate_params([
        %Validator{action: :at_least_one_of, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo", bar: "bar"})

    assert_raise Maru.Exceptions.Validation, fn ->
      Endpoint.validate_params([
        %Validator{action: :mutually_exclusive, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo", bar: "bar"})
    end
  end

  test "dispatch method" do
    defmodule DispatchTest do
      use Maru.Helpers.Response
      Module.eval_quoted __MODULE__, (
        %Maru.Router.Endpoint{
          method: "GET", path: [], block: {:text, [], [{:conn, [], nil}, "get"]}
        } |> Endpoint.dispatch
      ), [], __ENV__
      Module.eval_quoted __MODULE__, (
        %Maru.Router.Endpoint{
          method: {:_, [], nil}, path: [], block: {:text, [], [{:conn, [], nil}, "match"]}
        } |> Endpoint.dispatch
      ), [], __ENV__
      def e(conn), do: endpoint(conn, [])
    end

    assert %Plug.Conn{resp_body: "get"} = conn(:get, "/") |> Maru.Plugs.Prepare.call([]) |> DispatchTest.e
    assert %Plug.Conn{resp_body: "match"} = conn(:post, "/") |> Maru.Plugs.Prepare.call([]) |> DispatchTest.e
  end
end
