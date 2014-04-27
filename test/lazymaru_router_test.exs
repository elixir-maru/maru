defmodule LazyHelper.RouterTest do
  use ExUnit.Case, async: true

  test "endpoint" do
    defmodule Test0 do
      use Lazymaru.Router
      post do: nil
    end
    assert Test0.endpoints == [{:post, [], [], {:do, nil}, nil}]
  end

  test "endpoint url param" do
    defmodule Test1 do
      use Lazymaru.Router
      get "foo/:bar", do: nil
    end
    assert Test1.endpoints == [{:get, ["foo", :param], [:bar], {:do, nil}, nil}]
  end

  test "endpoint params DSL" do
    defmodule Test2 do
      use Lazymaru.Router
      params do: nil
      put do: nil
    end
    assert [{:put, [], [], {:do, nil}, {:__block__, [], _}}] = Test2.endpoints
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
    assert [{:delete, ["foo", :param, "baz"], [:bar], [do: nil], {:__block__, [], _}}] = Test3.endpoints
  end
end