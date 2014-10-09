defmodule Lazymaru.RouterTest do
  use ExUnit.Case , async: true
  alias Lazymaru.Router.Param

  test "optional requires group" do
    defmodule Test do
      use Lazymaru.Router
      params do
        requires :foo, type: :string, regexp: ~r/^[a-z]+$/
        group :group do
          group :group, type: Map do
            optional :bar, type: Integer, range: 1..100
          end
        end
      end
      def pc, do: @param_context
    end

    assert [ %Param{attr_name: :foo,   parser: Lazymaru.ParamType.String,  required: true, validators: [regexp: ~r/^[a-z]+$/]},
             %Param{attr_name: :group, parser: Lazymaru.ParamType.List,    required: true, nested: true},
             %Param{attr_name: :group, parser: Lazymaru.ParamType.Map,     required: true, nested: true, group: [:group]},
             %Param{attr_name: :bar,   parser: Lazymaru.ParamType.Integer, required: false, group: [:group, :group], validators: [range: 1..100]}
           ] == Test.pc
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

    assert %Lazymaru.Router.Resource{ param_context: [], path: ["level1", "level2", :param]
                                    } == Test.resource
  end
end
