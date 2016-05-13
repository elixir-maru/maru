defmodule Maru.Builder.BeforeTest do
  use ExUnit.Case, async: true

  alias Maru.Struct.Plug, as: MaruPlug

  test "top-level plug" do
    defmodule PlugOverridableTest do
      use Maru.Router, make_plug: true

      before do
        plug Plug.Logger
      end

      plug :a
      pipeline do
        plug :b
      end
      def p1, do: @resource.plugs
      def p2, do: MaruPlug.merge(@resource.plugs, @plugs)
      def p3, do: @plugs_before
    end

    assert [
      %MaruPlug{name: nil, plug: :a},
    ] = PlugOverridableTest.p1

    assert [
      %MaruPlug{name: nil, plug: :a},
      %MaruPlug{name: nil, plug: :b},
    ] = PlugOverridableTest.p2

    assert [
      {Plug.Logger, [], true}
    ] = PlugOverridableTest.p3
  end

end
