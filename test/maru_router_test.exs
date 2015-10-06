defmodule Maru.RouterTest do
  use ExUnit.Case, async: true
  alias Maru.Router.Param
  alias Maru.Router.Validator

  test "optional requires group" do
    defmodule OptionalTest do
      use Maru.Router
      params do
        requires :foo, type: :string, regexp: ~r/^[a-z]+$/, desc: "hehe"
        group :group do
          group :group, type: Map do
            optional :bar, type: Integer, range: 1..100
          end
        end
      end
      def pc, do: @param_context
    end

    assert [
      %Param{attr_name: :foo, parser: :string, required: true, validators: [regexp: ~r/^[a-z]+$/], desc: "hehe"},
      %Param{attr_name: :group, parser: :list, required: true, children: [
        %Param{attr_name: :group, parser: :map, required: true, children: [
          %Param{attr_name: :bar, parser: :integer, required: false, validators: [range: 1..100]}
        ]}
      ]}
    ] = OptionalTest.pc
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
      end
      def pc, do: @param_context
    end

    assert [
      %Validator{action: :mutually_exclusive, attr_names: [:a, :b, :c]},
      %Param{attr_name: :group, required: true, children: [
        %Validator{action: :exactly_one_of, attr_names: [:a, :b, :c]},
        %Validator{action: :at_least_one_of, attr_names: [:a, :b, :c]}
      ]}
    ] = ValidatorsTest.pc
  end


  test "resources" do
    defmodule ResourcesTest do
      use Maru.Router
      resources :level1 do
        resource :level2 do
          route_param :param do
            def resource, do: @resource
          end
        end
      end
    end

    assert %Maru.Router.Resource{path: ["level1", "level2", :param]} = ResourcesTest.resource
  end

  test "complex resources" do
    defmodule ComplexResourcesTest do
      use Maru.Router
      resource "foo/:bar" do
        def resource, do: @resource
      end
    end

    assert %Maru.Router.Resource{path: ["foo", :bar]} = ComplexResourcesTest.resource
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

      def pc, do: @param_context
    end

    assert [
      %Param{attr_name: :foo, coerce_with: :base64},
      %Param{attr_name: :bar, coerce_with: {:fn, _, _}},
      %Param{attr_name: :baz, coerce_with: f}
    ] = Coercion.pc

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

      helpers Maru.RouterTest.Helper
      helpers do
        params :foo2 do
          optional :qux
        end
      end

      params do
        requires :foo
        use [:foo0, :foo1, :foo2]
      end

      def pc, do: @param_context
    end

    assert [
      %Param{attr_name: :foo},
      %Param{attr_name: :bar},
      %Param{attr_name: :baz},
      %Param{attr_name: :qux},
    ] = SharedParamsTest.pc
  end
end
