defmodule Maru.HelperTest do
  use ExUnit.Case, async: true

  test "shared params" do
    defmodule Test do
      use Maru.Helper

      params :foo do
        requests :bar, type: String
      end
    end

    assert [foo: {:requests, _, [:bar, _]}] = Test.__shared_params__
  end
end
