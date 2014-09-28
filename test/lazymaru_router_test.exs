defmodule Lazymaru.RouterTest do
  use ExUnit.Case , async: true

  test "optional and requires" do
    defmodule Test do
      use Lazymaru.Router
      requires :foo, type: :string, regexp: ~r/^[a-z]+$/
      optional :bar, type: Integer, range: 1..100
      def pc, do: @param_context
    end

    assert %{ foo: %{default: nil, value: nil, required: true, parser: Lazymaru.ParamType.String, validators: [regexp: ~r/^[a-z]+$/]},
              bar: %{default: nil, value: nil, required: false, parser: Lazymaru.ParamType.Integer, validators: [range: 1..100]}
            } == Test.pc
  end


  test "resources" do
    defmodule Test do
      use Lazymaru.Router
      resources :level1 do
        resource :level2 do
          route_param :param do
            def resource, do: @resource
          end
        end
      end
    end

    assert %Lazymaru.Router.Resource{ params: %{}, path: ["level1", "level2", :param]
                                    } == Test.resource
  end
end
