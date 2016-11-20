defmodule Maru.Builder.MountLinkTest do
  use ExUnit.Case, async: true
  alias Maru.Builder.MountLink

  test "get mount link" do
    MountLink.put_father(A, B)
    MountLink.put_father(A, C)
    MountLink.put_father(B, C)
    assert [A, C] = MountLink.get_mount_link(A, [C])
    assert [A, B, C] = MountLink.get_mount_link(A, [B])
    assert_raise CompileError, fn ->
      MountLink.get_mount_link(A, [])
    end

    MountLink.put_father(M, N)
    MountLink.put_father(N, O)
    MountLink.put_father(O, P)
    assert [M, N, O, P] = MountLink.get_mount_link(M, [])
  end
end
