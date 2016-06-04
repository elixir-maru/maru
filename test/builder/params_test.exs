defmodule Maru.Builder.ParamsTest do
  use ExUnit.Case, async: true

  alias Maru.Struct.Parameter, as: P
  alias Maru.Struct.Parameter.Information, as: PI
  alias Maru.Struct.Validator, as: V
  alias Maru.Struct.Validator.Information, as: VI
  alias Maru.Struct.Resource

  test "optional requires group" do
    defmodule Elixir.Maru.Validations.Range do
    end

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
      %P{information: %PI{attr_name: :group, required: true, children: [
        %PI{attr_name: :group, required: true, children: [
          %PI{attr_name: :bar, required: false}
        ]}
      ]}}
    ] = OptionalTest.parameters
  end


  test "validators" do
    defmodule ValidatorsTest do
      use Maru.Router

      params do
        mutually_exclusive [:a, :b, :c]
        group :group do
          exactly_one_of  [:a, :b, :c]
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
      %P{information: %PI{attr_name: :group, children: [
        %VI{action: :exactly_one_of},
        %VI{action: :at_least_one_of},
      ]}},
      %P{information: %PI{attr_name: :group2, children: [
        %PI{attr_name: :id, children: []},
        %PI{attr_name: :name, children: []},
        %VI{action: :at_least_one_of},
      ]}}
    ] = ValidatorsTest.parameters
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

    assert %Resource{path: ["level1", "level2", :param]} = ResourcesTest.resource
    assert [%P{information: %PI{attr_name: :param_with_options, required: true}}] = ResourcesTest.parameters
  end


  test "complex resources" do
    defmodule ComplexResourcesTest do
      use Maru.Router

      resource "foo/:bar" do
        def resource, do: @resource
      end
    end

    assert %Resource{path: ["foo", :bar]} = ComplexResourcesTest.resource
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
    ] = CustomType.parameters
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

      helpers do
        params :foo2 do
          optional :qux
        end
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
      %P{information: %PI{attr_name: :qux}},
    ] = SharedParamsTest.parameters
  end

end
