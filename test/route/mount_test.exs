defmodule Maru.Route.MountTest do
  use ExUnit.Case, async: true

  test "mount" do
    defmodule Mounted do
      def __routes__ do
        [%Maru.Router{}]
      end
    end

    defmodule MountedAlias do
      def __routes__ do
        [%Maru.Router{}]
      end
    end

    defmodule MountTest do
      use Maru.Router
      alias Maru.Route.MountTest.MountedAlias

      mount Maru.Route.MountTest.Mounted
      mount MountedAlias

      def m, do: @mounted
    end

    assert [%Maru.Router{}, %Maru.Router{}] = MountTest.m
  end

end
