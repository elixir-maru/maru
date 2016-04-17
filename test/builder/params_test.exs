defmodule Maru.Builder.ParamsTest do
  use ExUnit.Case, async: true

  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator
  alias Maru.Struct.Resource

  test "optional requires group" do
    defmodule OptionalTest do
      use Maru.Router

      params do
        optional :attr
        requires :foo, type: :string, regexp: ~r/^[a-z]+$/, desc: "hehe"
        group :group do
          group :group, type: Map do
            optional :bar, type: Integer, range: 1..100
          end
        end
      end

      def parameters, do: @parameters
    end

    assert [
      %Parameter{attr_name: :attr, parser: :term, required: false},
      %Parameter{attr_name: :foo, parser: :string, required: true, validators: [regexp: ~r/^[a-z]+$/], desc: "hehe"},
      %Parameter{attr_name: :group, parser: :list, required: true, children: [
        %Parameter{attr_name: :group, parser: :map, required: true, children: [
          %Parameter{attr_name: :bar, parser: :integer, required: false, validators: [range: 1..100]}
        ]}
      ]}
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
      %Validator{action: :mutually_exclusive, attr_names: [:a, :b, :c]},
      %Parameter{attr_name: :group, required: true, children: [
        %Validator{action: :exactly_one_of, attr_names: [:a, :b, :c]},
        %Validator{action: :at_least_one_of, attr_names: [:a, :b, :c]}
      ]},
      %Parameter{attr_name: :group2, required: true, children: [
        %Parameter{attr_name: :id, required: false, children: []},
        %Parameter{attr_name: :name, required: false, children: []},
        %Validator{action: :at_least_one_of, attr_names: [:id, :name]}
      ]}
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
    assert [%Parameter{attr_name: :param_with_options, parser: :integer, required: true}] = ResourcesTest.parameters
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


  test "test coercion" do
    defmodule Coercion do
      use Maru.Router

      helpers do
        def baz(s), do: s
      end

      params do
        optional :foo, coerce_with: Base64
        optional :bar, coerce_with: fn s -> s end
        optional :baz, coerce_with: &Coercion.baz/1
      end

      def parameters, do: @parameters
    end

    assert [
      %Parameter{attr_name: :foo, coerce_with: :base64},
      %Parameter{attr_name: :bar, coerce_with: {:fn, _, _}},
      %Parameter{attr_name: :baz, coerce_with: f}
    ] = Coercion.parameters

    assert is_function(f)
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
      %Parameter{attr_name: :foo},
      %Parameter{attr_name: :bar},
      %Parameter{attr_name: :baz},
      %Parameter{attr_name: :qux},
    ] = SharedParamsTest.parameters
  end

end
