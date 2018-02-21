defmodule Maru.Plugs.NotFoundTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "plug notfound" do
    conn = conn(:get, "/")

    assert_raise Maru.Exceptions.NotFound, fn ->
      conn |> Maru.Plugs.NotFound.call([])
    end
  end
end
