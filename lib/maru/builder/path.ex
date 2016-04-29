defmodule Maru.Builder.Path do
  @moduledoc false

  @doc false
  def split(path) when is_atom(path), do: [path |> to_string]
  def split(path) when is_binary(path) do
    func = fn
      ("", r) -> r
      (":" <> param, r) -> [param |> String.to_atom | r]
      (p, r) -> [p | r]
    end
    path |> String.split("/") |> Enum.reduce([], func) |> Enum.reverse
  end
  def split(_path), do: raise "path should be Atom or String"


  @doc false
  def parse_params(conn_path_info, route_path) do
    do_parse_params(conn_path_info, route_path , %{})
  end

  defp do_parse_params([], [], result), do: result
  defp do_parse_params([h|t1], [h|t2], result) do
    do_parse_params(t1, t2, result)
  end
  defp do_parse_params([h1|t1], [h2|t2], result) when is_atom(h2) do
    do_parse_params(t1, t2, put_in(result, [to_string(h2)], h1))
  end

end
