defmodule Lazymaru.Utils do
  def upper_camel_case(s) do
    s |> String.split("_") |> Enum.map(
      fn i -> i |> String.capitalize end
    ) |> Enum.join("")
  end
end
