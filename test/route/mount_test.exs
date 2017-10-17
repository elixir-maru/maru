defmodule Maru.Route.MountTest do
  use ExUnit.Case, async: true

  test "mount" do
    defmodule Mounted do
      def __routes__ do
        [%Maru.Route{}]
      end
    end

    defmodule MountedAlias do
      def __routes__ do
        [%Maru.Route{}]
      end
    end

    defmodule MountTest do
      use Maru.Router
      alias Maru.Route.MountTest.MountedAlias

      mount Maru.Route.MountTest.Mounted
      mount MountedAlias

      def m, do: @mounted
    end

    assert [%Maru.Route{}, %Maru.Route{}] = MountTest.m
  end

end
