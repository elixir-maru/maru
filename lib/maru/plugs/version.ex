defmodule Maru.Plugs.GetVersion do
  @moduledoc """
  This module is a plug, fetch `version` from connection and write to private variable `maru_version`.
  """

  alias Plug.Conn

  @doc false
  def init(opts) do
    opts
  end

  @doc false
  def call(conn, :accept_version_header) do
    vsn =
      case Conn.get_req_header(conn, "accept-version") do
        [version] -> version
        _ -> nil
      end

    conn |> Conn.put_private(:maru_version, vsn)
  end

  def call(conn, {:parameter, key}) do
    conn = conn |> Conn.fetch_query_params()
    vsn = conn.params |> Map.get(key)
    conn |> Conn.put_private(:maru_version, vsn)
  end

  def call(conn, {:accept_header, vendor}) do
    size = byte_size(vendor)

    vsn =
      with [version] <- Conn.get_req_header(conn, "accept"),
           [_, s, _] <- String.split(version, ["/", "+"]),
           <<"vnd.", ^vendor::binary-size(size), "-", vsn::binary>> <- s do
        vsn
      else
        _ -> nil
      end

    conn |> Conn.put_private(:maru_version, vsn)
  end
end

defmodule Maru.Plugs.PutVersion do
  @moduledoc """
  This module is a plug, put version to private variable `maru_version`.
  """

  @doc false
  def init(version) do
    version
  end

  @doc false
  def call(conn, version) do
    Plug.Conn.put_private(conn, :maru_version, version)
  end
end
