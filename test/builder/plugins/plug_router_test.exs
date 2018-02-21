defmodule Maru.Builder.PlugRouterTest do
  use ExUnit.Case, async: true

  alias Maru.Resource.MaruPlug

  test "plug-router" do
    defmodule PlugRouterOverridableTest do
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
             %MaruPlug{name: nil, plug: :a}
           ] = PlugRouterOverridableTest.p1()

    assert [
             %MaruPlug{name: nil, plug: :a},
             %MaruPlug{name: nil, plug: :b}
           ] = PlugRouterOverridableTest.p2()

    assert [
             {Plug.Logger, [], true}
           ] = PlugRouterOverridableTest.p3()
  end

  test "normal router with before" do
    assert_raise CompileError, ~r/undefined function before/, fn ->
      defmodule NormalRouterWithBeforeTest do
        use Maru.Router

        before do
          plug Plug.Logger
        end
      end
    end
  end
end
