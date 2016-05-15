defmodule Maru.Builder.RouteTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Maru.Builder.Route
  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator
  alias Maru.Coercions, as: C
  alias Maru.Validations, as: V

  defp do_parse(parameters, data, result \\ %{}) do
    result = result |> Macro.escape
    data   = data |> Macro.escape
    body   = Enum.reduce(parameters, result, &Route.quote_param(&1, &2, data))
    Code.eval_quoted(body) |> elem(0)
  end

  test "validate param" do
    assert %{id: 1} == do_parse([%Parameter{attr_name: :id, type: C.Integer, coercer: {:module, C.Integer}}], %{"id" => 1})
    assert %{} == do_parse([%Parameter{attr_name: :id, type: C.Integer, coercer: {:module, C.Integer}, required: false}], %{})
    assert %{bool: false} == do_parse([%Parameter{attr_name: :bool, type: C.Boolean, coercer: {:module, C.Boolean}, required: false}], %{"bool" => "false"})
    assert_raise Maru.Exceptions.InvalidFormatter, fn ->
      do_parse([%Parameter{attr_name: :id, type: C.Integer, coercer: {:module, C.Integer}}], %{"id" => "id"})
    end
    assert_raise Maru.Exceptions.Validation, fn ->
      do_parse([%Parameter{attr_name: :id, type: C.Integer, coercer: {:module, C.Integer}, validators: [{V.Values, quote do 1..10 end}]}], %{"id" => "100"})
    end
  end

  test "identical param keys in groups" do
    assert %{group: %{name: "name1"}, name: "name2"} =
      [ %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}},
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Map}, children: [
          %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}}
        ]},
      ] |> do_parse(%{"group" => %{"name" => "name1"}, "name" => "name2"})
  end

  test "validate Map nested param" do
    assert %{group: %{name: "name"}} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Map}, children: [
          %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}}
        ]}
      ], %{"group" => %{"name" => "name"}})

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Map}, children: [
          %Parameter{attr_name: :group2, type: C.Map, coercer: {:module, C.Map}, children: [
            %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}},
            %Parameter{attr_name: :name2, type: C.String, coercer: {:module, C.String}},
          ]}
        ]}
      ], %{"group" => %{"group2" => %{"name" => "name", "name2" => "name2"}}})
  end

  test "validate List nested param" do
    assert %{group: [%{foo: "foo1", bar: "default"}, %{foo: "foo2", bar: "bar"}]} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.List, coercer: {:module, C.List}, children: [
          %Parameter{attr_name: :foo, type: C.String, coercer: {:module, C.String}},
          %Parameter{attr_name: :bar, type: C.String, coercer: {:module, C.String}, default: "default"},
          %Validator{validator: V.AtLeastOneOf, attr_names: [:foo, :bar]},
        ]}
      ], %{"group" => [%{"foo" => "foo1"}, %{"foo" => "foo2", "bar" => "bar"}]})

    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.List, coercer: {:module, C.List}, children: [
          %Parameter{attr_name: :foo, type: C.List, coercer: {:module, C.List}, children: [
            %Parameter{attr_name: :bar, type: C.Map, coercer: {:module, C.Map}, children: [
              %Parameter{attr_name: :baz, type: C.String, coercer: {:module, C.String}}
            ]}
          ]}
        ]}
      ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]})

    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.List, coercer: {:module, C.List}, children: [
          %Parameter{attr_name: :foo, type: C.List, coercer: {:module, C.List}, children: [
            %Parameter{attr_name: :bar, type: C.Map, coercer: {:module, C.Map}, children: [
              %Parameter{attr_name: :baz, type: C.String, coercer: {:module, C.String}}
            ]}
          ]}
        ]}
      ], %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]})
  end

  test "validate Json nested param" do
    assert %{group: %{name: "name"}} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Json}, children: [
          %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}}
        ]}
      ], %{"group" => ~s({"name":"name"})})

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Map}, children: [
          %Parameter{attr_name: :group2, type: C.Map, coercer: {:module, C.Json}, children: [
            %Parameter{attr_name: :name, type: C.String, coercer: {:module, C.String}},
            %Parameter{attr_name: :name2, type: C.String, coercer: {:module, C.String}},
          ]}
        ]}
      ], %{"group" => %{"group2" => ~s({"name2":"name2","name":"name"})}})
  end

  test "param rename" do
    assert %{group: %{name: "name"}} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Json}, children: [
          %Parameter{attr_name: :name, source: "name-test", type: C.String, coercer: {:module, C.String}}
        ]}
      ], %{"group" => ~s({"name-test":"name"})})
  end

  test "validate optional nested param" do
    assert %{} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.List, coercer: {:module, C.List}, required: false, children: [
          %Parameter{attr_name: :foo, type: C.String, coercer: {:module, C.String}, required: true},
        ]}
      ], %{})

    assert %{} ==
      do_parse([
        %Parameter{attr_name: :group, type: C.Map, coercer: {:module, C.Map}, required: false, children: [
          %Parameter{attr_name: :foo, type: C.String, coercer: {:module, C.String}, required: true}
        ]}
      ], %{})
  end

  test "validate Action Validator" do
    assert %{foo: "foo"} ==
      do_parse([
        %Validator{validator: V.ExactlyOneOf, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo"})

    assert %{foo: "foo", bar: "bar"} ==
      do_parse([
        %Validator{validator: V.AtLeastOneOf, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo", bar: "bar"})

    assert_raise Maru.Exceptions.Validation, fn ->
      do_parse([
        %Validator{validator: V.MutuallyExclusive, attr_names: [:foo, :bar, :baz]}
      ], %{}, %{foo: "foo", bar: "bar"})
    end
  end

  test "dispatch method" do
    defmodule DispatchTest do
      use Maru.Helpers.Response

      def endpoint(conn, 0) do
        conn |> Plug.Conn.send_resp(200, "get") |> Plug.Conn.halt
      end

      def endpoint(conn, 1) do
        conn |> Plug.Conn.send_resp(200, "match") |> Plug.Conn.halt
      end

      adapter = Maru.Builder.Versioning.None
      Module.eval_quoted __MODULE__, (
        Route.dispatch(%Maru.Struct.Route{
          method: "GET", path: [], module: __MODULE__, func_id: 0,
        }, __ENV__, adapter)
      ), [], __ENV__

      Module.eval_quoted __MODULE__, (
        Route.dispatch(%Maru.Struct.Route{
          method: {:_, [], nil}, path: [], module: __MODULE__, func_id: 1,
        }, __ENV__, adapter)
      ), [], __ENV__

      def r(conn), do: route(conn, [])
    end

    assert %Plug.Conn{resp_body: "get"} = conn(:get, "/") |> DispatchTest.r
    assert %Plug.Conn{resp_body: "match"} = conn(:post, "/") |> DispatchTest.r
  end

  test "method not allow" do
    defmodule MethodNotAllowTest do
      use Maru.Helpers.Response

      adapter = Maru.Builder.Versioning.None
      Module.eval_quoted __MODULE__, (
        Route.dispatch_405("v1", [], adapter)
      ), [], __ENV__

      def r(conn), do: route(conn, [])
    end

    assert_raise Maru.Exceptions.MethodNotAllow, fn ->
      conn(:get, "/") |> MethodNotAllowTest.r
    end
  end

end
