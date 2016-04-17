defmodule Maru.Builder.NamespacesTest do
  use ExUnit.Case, async: true

  alias Maru.Struct.Resource
  alias Maru.Struct.Parameter

  test "namespaces" do
    defmodule Test do
      use Maru.Builder

      resources :p1 do
        def r1, do: @resource

        resource :p2 do
          def r2, do: @resource
        end

        route_param :p3, type: Integer do
          def r3, do: @resource

          segment :p4 do
            def r4, do: @resource
          end
        end

        group :p5 do
          def r5, do: @resource
        end

      end
    end

    assert %Resource{path: ["p1"]} = Test.r1
    assert %Resource{path: ["p1", "p2"]} = Test.r2
    assert %Resource{
      path: ["p1", :p3],
      parameters: [%Parameter{attr_name: :p3, parser: :integer}],
    } = Test.r3
    assert %Resource{
      path: ["p1", :p3, "p4"],
      parameters: [%Parameter{attr_name: :p3, parser: :integer}],
    } = Test.r4
    assert %Resource{path: ["p1", "p5"], parameters: []} = Test.r5
  end

end
