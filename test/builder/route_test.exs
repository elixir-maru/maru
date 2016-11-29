defmodule Maru.Builder.RouteTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Maru.Builder.Route, warn: false

  defp do_parse(parameters, data, result \\ %{}) do
    runtime = Enum.map(parameters, fn p -> p.runtime end)
    data = data |> Macro.escape
    result = result |> Macro.escape
    quote do
      Maru.Runtime.parse_params(
        unquote(runtime),
        unquote(result),
        unquote(data)
      )
    end |> Code.eval_quoted([], __ENV__) |> elem(0)
  end

  test "validate param" do
    defmodule ValidateParam do
      use Maru.Builder

      params do
        requires :id, type: Integer
      end
      def p1, do: @parameters
      @parameters []

      params do
        optional :id, type: Integer
      end
      def p2, do: @parameters
      @parameters []

      params do
        optional :bool, type: Boolean
      end
      def p3, do: @parameters
      @parameters []

      params do
        optional :id, type: Integer
      end
      def p4, do: @parameters
      @parameters []

      params do
        optional :id, type: Integer, values: 1..10
      end
      def p5, do: @parameters
    end

    assert %{id: 1} = do_parse(ValidateParam.p1, %{"id" => 1})
    assert %{} == do_parse(ValidateParam.p2, %{})
    assert %{bool: false} == do_parse(ValidateParam.p3, %{"bool" => "false"})
    assert_raise Maru.Exceptions.InvalidFormat, fn ->
      do_parse(ValidateParam.p4, %{"id" => "id"})
    end
    assert_raise Maru.Exceptions.Validation, fn ->
      do_parse(ValidateParam.p5, %{"id" => "100"})
    end
  end

  test "identical param keys in groups" do
    defmodule IdenticalParamKeys do
      use Maru.Builder

      params do
        optional :name
        group :group, type: Map do
          optional :name
        end
      end
      def p, do: @parameters
    end

    assert %{group: %{name: "name1"}, name: "name2"} = do_parse(
      IdenticalParamKeys.p,
      %{"group" => %{"name" => "name1"}, "name" => "name2"}
    )
  end

  test "validate Map nested param" do
    defmodule MapNestedParam do
      use Maru.Builder

      params do
        group :group, type: Map do
          group :group2, type: Map do
            optional :name
            optional :name2
          end
        end
      end
      def p, do: @parameters
    end

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      do_parse(
        MapNestedParam.p,
        %{"group" => %{"group2" => %{"name" => "name", "name2" => "name2"}}}
      )
  end

  test "validate List nested param" do
    defmodule ListNestedParam do
      use Maru.Builder

      params do
        group :group, type: List do
          requires :foo
          optional :bar, default: "default"
          at_least_one_of [:foo, :bar]
        end
      end
      def p1, do: @parameters
      @parameters []

      params do
        group :group, type: List do
          group :foo, type: List do
            optional :bar, type: Map do
              optional :baz
              at_least_one_of :above_all
            end
          end
        end
      end
      def p2, do: @parameters
    end

    assert %{group: [%{foo: "foo1", bar: "default"}, %{foo: "foo2", bar: "bar"}]} ==
      do_parse(
        ListNestedParam.p1,
        %{"group" => [%{"foo" => "foo1"}, %{"foo" => "foo2", "bar" => "bar"}]}
      )

    assert %{group: [%{foo: [%{bar: %{baz: "baz"}}]}]} ==
      do_parse(
        ListNestedParam.p2,
        %{"group" => [%{"foo" => [%{"bar" => %{"baz" => "baz"}}]}]}
      )
  end

  test "validate one-line List nested param" do
    defmodule OneLineListNestedParam do
      use Maru.Builder

      params do
        optional :foo, type: List[Integer]
        optional :bar, type: List[Float |> String]
        optional :baz, type: List[List[Integer]]
      end
      def p, do: @parameters
    end

    assert %{
      foo: [1, 2, 3],
      bar: ["1.0", "2.0", "3.0"],
      baz: [[1], [2], [3]],
    } = do_parse(
      OneLineListNestedParam.p,
      %{ "foo" => ["1", "2", "3"],
         "bar" => [1, 2, 3],
         "baz" => [["1"], ["2"], ["3"]],
      }
    )
  end

  test "validate nested types" do
    defmodule NestedTypes do
      use Maru.Builder

      params do
        group :group, type: Json |> Map do
          requires :name
        end
      end
      def p1, do: @parameters
      @parameters []

      params do
        group :group, type: Map do
          group :group2, type: Json |> Map do
            requires :name
            requires :name2
          end
        end
      end
      def p2, do: @parameters
    end

    assert %{group: %{name: "name"}} ==
      do_parse(
        NestedTypes.p1,
        %{"group" => ~s({"name":"name"})}
      )

    assert %{group: %{group2: %{name: "name", name2: "name2"}}} ==
      do_parse(
        NestedTypes.p2,
        %{"group" => %{"group2" => ~s({"name2":"name2","name":"name"})}}
      )
  end

  test "rename param" do
    defmodule RenameParam do
      use Maru.Builder

      params do
        group :group, type: Json |> Map do
          requires :name, source: "name-test"
        end
      end
      def p, do: @parameters
    end

    assert %{group: %{name: "name"}} ==
      do_parse(
        RenameParam.p,
        %{"group" => ~s({"name-test":"name"})}
      )
  end

  test "validate optional nested param" do
    defmodule OptionalNestedParam do
      use Maru.Builder

      params do
        optional :group do
          optional :foo
        end
      end
      def p1, do: @parameters

      params do
        optional :group, type: Map do
          optional :foo
        end
      end
      def p2, do: @parameters

      params do
        optional :foo, default: nil
        optional :bar, default: false
      end
      def p3, do: @parameters
    end

    assert %{} == do_parse(OptionalNestedParam.p1, %{})
    assert %{} == do_parse(OptionalNestedParam.p2, %{})
    assert %{foo: nil, bar: false} == do_parse(OptionalNestedParam.p3, %{})
  end

  test "keep_blank" do
    defmodule KeepBlank do
      use Maru.Builder

      params do
        optional :foo, keep_blank: true
        optional :bar, default: nil
        optional :baz, keep_blank: true, default: nil
      end
      def p1, do: @parameters
    end

    assert %{bar: nil, baz: nil} == do_parse(KeepBlank.p1, %{})

    assert %{foo: nil, bar: nil, baz: nil} == do_parse(KeepBlank.p1, %{"foo" => nil})
    assert %{foo: nil, bar: nil, baz: ""} == do_parse(KeepBlank.p1, %{"foo" => nil, "bar" => "", "baz" => ""})

    assert %{foo: "", bar: nil, baz: nil} == do_parse(KeepBlank.p1, %{"foo" => ""})
    assert %{foo: "", bar: nil, baz: ""} == do_parse(KeepBlank.p1, %{"foo" => "", "bar" => "", "baz" => ""})
  end

  test "parameter dependent" do
    defmodule ParameterDependentTest do
      use Maru.Builder

      params do
        optional :foo, type: Integer
        given :foo do
          optional :bar, type: Integer
          given [bar: &(&1 > 10)] do
            optional :baz, type: Integer
          end
        end
        given [:foo, :baz, bar: fn bar -> bar > 100 end] do
          requires :qux, type: Integer
        end
      end
      def parameters, do: @parameters
    end

    p = ParameterDependentTest.parameters
    assert %{} = do_parse(p, %{})
    assert %{foo: 1} = do_parse(p, %{"foo" => 1})
    assert %{foo: 1, bar: 2} = do_parse(p, %{"foo" => 1, "bar" => 2})
    assert %{foo: 1, bar: 11, baz: 2} = do_parse(p, %{"foo" => 1, "bar" => 11, "baz" => 2, "qux" => 3})
    assert %{foo: 1, bar: 111, baz: 2, qux: 3} = do_parse(p, %{"foo" => 1, "bar" => 111, "baz" => 2, "qux" => 3})
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

  test "method not allowed" do
    defmodule MethodNotAllowedTest do
      use Maru.Helpers.Response

      adapter = Maru.Builder.Versioning.None
      Module.eval_quoted __MODULE__, (
        Route.dispatch_405("v1", [], [], adapter)
      ), [], __ENV__

      def r(conn), do: route(conn, [])
    end

    assert_raise Maru.Exceptions.MethodNotAllowed, fn ->
      conn(:get, "/") |> MethodNotAllowedTest.r
    end
  end

  test "routes order" do
    defmodule RoutesOrderTest.A do
      use Maru.Router
      @test false

      get :a do
        conn |> text("a")
      end
    end

    defmodule RoutesOrderTest.B do
      use Maru.Router
      @test false

      get :b do
        conn |> text("b")
      end

      get :bb do
        conn |> text("bb")
      end

      mount Maru.Builder.RouteTest.RoutesOrderTest.A
    end

    defmodule RoutesOrderTest.C do
      use Maru.Router
      @test false

      get :c do
        conn |> text("c")
      end

      get :cc do
        conn |> text("cc")
      end
    end

    defmodule RoutesOrderTest.D do
      use Maru.Router
      @test false

      route_param :d do
        get do
          conn |> text("d")
        end
      end

      mount Maru.Builder.RouteTest.RoutesOrderTest.B
      mount Maru.Builder.RouteTest.RoutesOrderTest.C
    end

    assert [
      %Maru.Struct.Route{path: [:d]},
      %Maru.Struct.Route{path: ["b"]},
      %Maru.Struct.Route{path: ["bb"]},
      %Maru.Struct.Route{path: ["a"]},
      %Maru.Struct.Route{path: ["c"]},
      %Maru.Struct.Route{path: ["cc"]},
    ] = Maru.Builder.RouteTest.RoutesOrderTest.D.__routes__
  end

end
