defmodule Maru.Builder.ParamsTest do
  use ExUnit.Case, async: true

  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator
  alias Maru.Struct.Resource
  alias Maru.Coercions, as: C

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
            optional :bar, type: Integer, range: 1..100
          end
        end
      end

      def parameters, do: @parameters
    end

    assert [
      %Parameter{attr_name: :attr, type: C.String, required: false},
      %Parameter{attr_name: :foo, type: C.String, required: true, validators: [{Maru.Validations.Regexp, {:sigil_r, _, _}}]},
      %Parameter{attr_name: :group, type: C.List, required: true, children: [
        %Parameter{attr_name: :group, type: C.Map, required: true, children: [
          %Parameter{attr_name: :bar, type: C.Integer, required: false, validators: [{Maru.Validations.Range, {:.., _, [1, 100]}}]}
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
      %Validator{validator: Maru.Validations.MutuallyExclusive, attr_names: [:a, :b, :c]},
      %Parameter{attr_name: :group, required: true, children: [
        %Validator{validator: Maru.Validations.ExactlyOneOf, attr_names: [:a, :b, :c]},
        %Validator{validator: Maru.Validations.AtLeastOneOf, attr_names: [:a, :b, :c]}
      ]},
      %Parameter{attr_name: :group2, required: true, children: [
        %Parameter{attr_name: :id, required: false, children: []},
        %Parameter{attr_name: :name, required: false, children: []},
        %Validator{validator: Maru.Validations.AtLeastOneOf, attr_names: [:id, :name]}
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
    assert [%Parameter{attr_name: :param_with_options, type: C.Integer, required: true}] = ResourcesTest.parameters
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
      %Parameter{attr_name: :foo, type: C.String, coercer: {:module, C.Base64}},
      %Parameter{attr_name: :bar, type: C.String, coercer: {:func, {:fn, _, _}}},
      %Parameter{attr_name: :baz, type: C.String, coercer: {:func, {:&, _, _}}}
    ] = Coercion.parameters
  end


  test "custom coercion" do
    defmodule Elixir.Maru.Coercions.MyCoercion do
      use Maru.Coercion

      def arguments do
        [:my_coercion]
      end
    end

    defmodule CustomCoercion do
      use Maru.Router

      params do
        optional :foo, type: Integer, coerce_with: MyCoercion, my_coercion: "arg"
      end

      def parameters, do: @parameters
    end

    assert [
      %Maru.Struct.Parameter{
        attr_name: :foo,
        type: Maru.Coercions.Integer,
        coercer: {:module, Maru.Coercions.MyCoercion},
        coercer_argument: {:%{}, [], [my_coercion: "arg"]},
        validators: []
      }
    ] = CustomCoercion.parameters
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
