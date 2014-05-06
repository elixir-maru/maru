defmodule Lazymaru.RouterTest do
  use ExUnit.Case, async: true

  test "endpoint" do
    defmodule Test0 do
      use Lazymaru.Router
      post do: nil
    end
    ep = Test0.endpoints |> List.first
    assert ep.method == :post
    assert ep.block == {:do, nil}
  end

  test "endpoint url param" do
    defmodule Test1 do
      use Lazymaru.Router
      get "foo/:bar", do: nil
    end
    ep = Test1.endpoints |> List.first
    assert ep.method == :get
    assert ep.path == ["foo", :param]
    assert ep.params == [:bar]
    assert ep.block == {:do, nil}
  end

  test "endpoint params DSL" do
    defmodule Test2 do
      use Lazymaru.Router
      params do: nil
      put do: nil
    end
    ep = Test2.endpoints |> List.first
    assert ep.method == :put
    assert ep.block == {:do, nil}
    assert {:__block__, [], _} = ep.params_block
  end

  test "namespace" do
    defmodule Test3 do
      use Lazymaru.Router
      resources :foo do
        route_param :bar do
          params do: nil
          delete :baz, do: nil
        end
      end
    end
    ep = Test3.endpoints |> List.first
    assert ep.method == :delete
    assert ep.path == ["foo", :param, "baz"]
    assert ep.params == [:bar]
    assert ep.block == [do: nil]
    assert {:__block__, [], _} = ep.params_block
  end
end