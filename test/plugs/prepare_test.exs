defmodule Maru.Plugs.PrepareTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "plug prepare" do
    conn = conn(:get, "/")
    assert %Plug.Conn{private: %{
      maru_resource_path: [],
      maru_route_path: [],
      maru_param_context: [],
      maru_version: nil
    }} = conn |> Maru.Plugs.Prepare.call([])
  end
end
