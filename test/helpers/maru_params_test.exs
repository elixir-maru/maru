defmodule Maru.Helpers.ParamsTest do
  use ExUnit.Case, async: true

  test "named params" do
    defmodule Test do
      import Maru.Helpers.Params

      params :foo do
        optional :bar, type: Integer
      end

      def sp, do: @shared_params
    end

    assert {:foo, {:optional, _, _}} = Test.sp
  end
end
