defmodule Maru.Builder.Plugins.Route.MountTest do
  use ExUnit.Case, async: true

  test "mount" do
    defmodule Mounted do
      def __routes__ do
        [%Maru.Builder.Plugins.Route{}]
      end
    end

    defmodule MountTest do
      use Maru.Router
      mount Maru.Builder.Plugins.Route.MountTest.Mounted

      def m, do: @mounted
    end

    assert [%Maru.Builder.Plugins.Route{}] = MountTest.m
  end
end
