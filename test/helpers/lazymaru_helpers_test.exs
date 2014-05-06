defmodule Lazymaru.HelperTest do
  use ExUnit.Case, async: true

  test "helper" do
    defmodule Test0 do
      def hh, do: nil
    end

    defmodule Test1 do
      use Lazymaru.Router

      helpers do
        def h, do: nil
      end

      helpers Test0
    end

    assert Test1.helpers == [Module.concat([:Test0]), Lazymaru.HelperTest.Test1]
  end
end