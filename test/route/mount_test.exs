defmodule Maru.Route.MountTest do
  use ExUnit.Case, async: true

  test "mount" do
    defmodule Mounted do
      def __routes__ do
        [%Maru.Route{}]
      end
    end

    defmodule MountTest do
      use Maru.Router
      mount Maru.Route.MountTest.Mounted

      def m, do: @mounted
    end

    assert [%Maru.Route{}] = MountTest.m
  end
end
