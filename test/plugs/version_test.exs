defmodule Maru.Plugs.VersionTest do
  use ExUnit.Case, async: true
  import Plug.Test
  alias Plug.Conn

  defp prepare(conn), do: conn |> Maru.Plugs.Prepare.call([])

  test "plug version path" do
    assert %Conn{private: %{maru_version: "v1"}} =
      conn(:get, "/v1") |> prepare |> Maru.Plugs.Version.call({:path, []})

    assert %Conn{private: %{maru_version: nil}} =
      conn(:get, "/") |> prepare |> Maru.Plugs.Version.call({:path, []})
  end

  test "plug version param" do
    assert %Conn{private: %{maru_version: "v1"}} =
    conn(:get, "/", %{"apiver" => "v1"}) |> prepare |> Maru.Plugs.Version.call({:param, []})

    assert %Conn{private: %{maru_version: "v2"}} =
      conn(:get, "/", %{"v" => "v2"}) |> prepare |> Maru.Plugs.Version.call({:param, [parameter: "v"]})

    assert %Conn{private: %{maru_version: nil}} =
      conn(:get, "/") |> prepare |> Maru.Plugs.Version.call({:path, []})
  end

  test "plug version accept version header" do
    assert %Conn{private: %{maru_version: "v1"}} =
      conn(:get, "/", nil, headers: [{"accept-version", "v1"}]) |> prepare |> Maru.Plugs.Version.call({:accept_version_header, []})

    assert %Conn{private: %{maru_version: nil}} =
      conn(:get, "/") |> prepare |> Maru.Plugs.Version.call({:accept_version_header, []})
  end
end
