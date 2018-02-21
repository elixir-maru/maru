defmodule Maru.Builder.ParamsTest do
  use ExUnit.Case, async: true

  alias Maru.Builder.Parameter, as: P
  alias P.Information, as: PI
  alias P.Dependent, as: D
  alias P.Dependent.Information, as: DI
  alias P.Validator, as: V
  alias P.Validator.Information, as: VI

  test "optional requires group" do
    defmodule OptionalTest do
      use Maru.Router

      params do
        optional :attr
        requires :foo, type: :string, regexp: ~r/^[a-z]+$/, desc: "hehe"

        group :group do
          group :group, type: Map do
            optional :bar, type: Integer, values: 1..100
          end
        end
      end

      def parameters, do: @parameters
    end

    assert [
             %P{information: %PI{attr_name: :attr, required: false}},
             %P{information: %PI{attr_name: :foo, required: true}},
             %P{
               information: %PI{
                 attr_name: :group,
                 required: true,
                 children: [
                   %PI{
                     attr_name: :group,
                     required: true,
                     children: [
                       %PI{attr_name: :bar, required: false}
                     ]
                   }
                 ]
               }
             }
           ] = OptionalTest.parameters()
  end

  test "parameter depend" do
    defmodule ParameterDependentTest do
      use Maru.Router

      params do
        optional :foo
        optional :bar

        given :foo do
          optional :baz, type: Integer

          given baz: &(&1 > 10) do
            requires :qux
          end
        end

        given [:foo, bar: fn bar -> bar > 10 end] do
          requires :qux
        end
      end

      def parameters, do: @parameters
    end

    assert [
             %P{information: %PI{attr_name: :foo}},
             %P{information: %PI{attr_name: :bar}},
             %D{
               information: %DI{
                 depends: [:foo],
                 children: [
                   %PI{attr_name: :baz},
                   %DI{
                     depends: [:baz],
                     children: [
                       %PI{attr_name: :qux}
                     ]
                   }
                 ]
               }
             },
             %D{
               information: %DI{
                 depends: [:foo, :bar],
                 children: [
                   %PI{attr_name: :qux}
                 ]
               }
             }
           ] = ParameterDependentTest.parameters()
  end

  test "validators" do
    defmodule ValidatorsTest do
      use Maru.Router

      params do
        mutually_exclusive [:a, :b, :c]

        group :group do
          exactly_one_of [:a, :b, :c]
          at_least_one_of [:a, :b, :c]
        end

        group :group2 do
          optional :id, type: Integer
          optional :name, type: String
          at_least_one_of :above_all
        end
      end

      def parameters, do: @parameters
    end

    assert [
             %V{information: %VI{action: :mutually_exclusive}},
             %P{
               information: %PI{
                 attr_name: :group,
                 children: [
                   %VI{action: :exactly_one_of},
                   %VI{action: :at_least_one_of}
                 ]
               }
             },
             %P{
               information: %PI{
                 attr_name: :group2,
                 children: [
                   %PI{attr_name: :id, type: "integer", children: []},
                   %PI{attr_name: :name, type: "string", children: []},
                   %VI{action: :at_least_one_of}
                 ]
               }
             }
           ] = ValidatorsTest.parameters()
  end

  test "resources" do
    defmodule ResourcesTest do
      use Maru.Router

      resources :level1 do
        resource :level2 do
          route_param :param do
            def resource, do: @resource
          end

          route_param :param_with_options, type: Integer do
            def parameters, do: @resource.parameters
          end
        end
      end
    end

    assert %Maru.Resource{path: ["level1", "level2", :param]} = ResourcesTest.resource()

    assert [%P{information: %PI{attr_name: :param_with_options, required: true}}] =
             ResourcesTest.parameters()
  end

  test "complex resources" do
    defmodule ComplexResourcesTest do
      use Maru.Router

      resource "foo/:bar" do
        def resource, do: @resource
      end
    end

    assert %Maru.Resource{path: ["foo", :bar]} = ComplexResourcesTest.resource()
  end

  test "custom Type" do
    defmodule Elixir.Maru.Types.MyType do
      use Maru.Type

      def arguments do
        [:my_arg]
      end
    end

    defmodule CustomType do
      use Maru.Router

      params do
        optional :foo, type: MyType, my_arg: "arg"
      end

      def parameters, do: @parameters
    end

    assert [
             %P{information: %PI{attr_name: :foo}}
           ] = CustomType.parameters()
  end

  test "shared params" do
    defmodule Helper do
      use Maru.Helper

      params :foo0 do
        optional :bar
      end

      params :foo1 do
        requires :baz
      end
    end

    defmodule SharedParamsTest do
      use Maru.Router

      helpers Maru.Builder.ParamsTest.Helper

      params :foo2 do
        optional :qux
      end

      params do
        requires :foo
        use [:foo0, :foo1, :foo2]
      end

      def parameters, do: @parameters
    end

    assert [
             %P{information: %PI{attr_name: :foo}},
             %P{information: %PI{attr_name: :bar}},
             %P{information: %PI{attr_name: :baz}},
             %P{information: %PI{attr_name: :qux}}
           ] = SharedParamsTest.parameters()
  end

  test "one line list test" do
    defmodule OneLineListTest do
      use Maru.Router

      params do
        requires :foo, type: List[Integer]
        requires :bar, type: List[List[:float]]
      end

      def parameters, do: @parameters
    end

    assert [
             %P{information: %PI{attr_name: :foo, type: {:list, "integer"}}},
             %P{information: %PI{attr_name: :bar, type: {:list, {:list, "float"}}}}
           ] = OneLineListTest.parameters()
  end
end
