defmodule Lazymaru.Router.Path do
  def split(path) when is_atom(path), do: [path |> to_string]
  def split(path) do
    func = fn ("", r) -> r
              (":" <> param, r) -> [param |> String.to_atom | r]
              (p, r) -> [p | r]
           end
    path |> String.split("/") |> Enum.reduce([], func) |> Enum.reverse
  end
end
