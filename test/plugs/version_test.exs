defmodule Maru.Plugs.GetVersionTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "accept_version_header" do
    conn =
      conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-version", "v3")
      |> Maru.Plugs.GetVersion.call(:accept_version_header)
    assert "v3" = conn.private.maru_version
  end

  test "parameter" do
    conn =
      conn(:get, "/?v=v1")
      |> Maru.Plugs.GetVersion.call({:parameter, "v"})
    assert "v1" = conn.private.maru_version
  end

  test "version_header" do
    conn =
      conn(:get, "/")
      |> Plug.Conn.put_req_header("accept", "application/vnd.twitter-v5+json")
      |> Maru.Plugs.GetVersion.call({:accept_header, "twitter"})
    assert "v5" = conn.private.maru_version
  end

end
