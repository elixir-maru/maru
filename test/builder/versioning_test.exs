defmodule Maru.Builder.VersioningTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Maru.Builder.Versioning, warn: false

  test "version with param" do
    adapter = Versioning.get_adapter(:param)
    assert Versioning.Parameter == adapter
    [{plug, args, _}] = adapter.get_version_plug([])
    conn = conn(:get, "/?apiver=v1", "") |> plug.call(args)
    assert "v1" == conn.private[:maru_version]
  end

  test "version with accept-version header" do
    adapter = Versioning.get_adapter(:accept_version_header)
    assert Versioning.AcceptVersionHeader == adapter
    [{plug, args, _}] = adapter.get_version_plug([])
    conn = conn(:get, "/", "") |> put_req_header("accept-version", "v1") |> plug.call(args)
    assert "v1" == conn.private[:maru_version]
  end

  test "version with accept header" do
    adapter = Versioning.get_adapter(:accept_header)
    assert Versioning.AcceptHeader == adapter
    [{plug, args, _}] = adapter.get_version_plug(vendor: :twitter)

    conn =
      conn(:get, "/", "")
      |> put_req_header("accept", "application/vnd.twitter-v1+json")
      |> plug.call(args)

    assert "v1" == conn.private[:maru_version]
  end
end
