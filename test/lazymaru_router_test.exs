defmodule Lazymaru.RouterTest do
  use ExUnit.Case , async: true

  test "params" do
    defmodule Test do
      use Lazymaru.Router
      params do: nil
      def pc, do: @param_context
    end

    assert %Lazymaru.Router.Params{ params: [], parsers: []
            } == Test.pc
  end

  test "optional and requires" do
    defmodule Test do
      use Lazymaru.Router
      @param_context %Lazymaru.Router.Params{params: [], parsers: []}
      requires :foo, type: :string, regexp: ~r/^[a-z]+$/
      optional :bar, type: Integer, range: 1..100
      def pc, do: @param_context
    end

    assert [ [param: :foo, required: true, parser: LazyParamType.String, regexp: ~r/^[a-z]+$/],
             [param: :bar, required: false, parser: LazyParamType.Integer, range: 1..100]
           ] == Test.pc.params
  end

  test "helpers" do
    defmodule Test do
      use Lazymaru.Router
      helpers Helper
      helpers do: nil
      def helpers, do: @helpers
    end

    assert [ Lazymaru.RouterTest.Test, Module.concat([:Helper])
           ] == Test.helpers
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

    assert %Lazymaru.Router.Resource{ params: nil, path: ["level1", "level2", :param]
            } == Test.resource
  end

  test "endpoint" do
    defmodule Test do
      use Lazymaru.Router

      get "path/:param", do: nil
      post do: nil
    end

    assert [ %Lazymaru.Router.Endpoint{block: nil, desc: nil,
              helpers: [], method: "GET", params: nil, path: ["path", :param]},
             %Lazymaru.Router.Endpoint{block: nil, desc: nil,
              helpers: [], method: "POST", params: nil, path: []},
           ] |> Macro.escape == Test.endpoints
  end

  test "mount" do
    defmodule TestBase do
      use Lazymaru.Router

      delete do: nil
    end

    defmodule Test do
      use Lazymaru.Router

      resources :mount do
        mount Lazymaru.RouterTest.TestBase
      end
    end

    assert [ %Lazymaru.Router.Endpoint{block: nil, desc: nil,
              helpers: [], method: "DELETE", params: nil, path: ["mount"]}
           ] |> Macro.escape == Test.endpoints
  end
end