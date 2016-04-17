defmodule Maru.Utils do
  @moduledoc false

  @doc false
  def upper_camel_case(s) do
    s |> String.split("_") |> Enum.map(
      fn i -> i |> String.capitalize end
    ) |> Enum.join("")
  end

  @doc false
  def lower_underscore(s) do
    for << i <- s >> , into: "" do
      if i in ?A..?Z do
        <<?\s, i + 32>>
      else
        <<i>>
      end
    end |> String.split |> Enum.join("_")
  end

  @doc """
  fork from elixir-1.3.0-dev for preserve ordering.
  """
  def group_by(enumerable, map \\ %{}, fun) when is_map(map) do
    enumerable
    |> Enum.reverse
    |> Enum.reduce(map, fn entry, categories ->
      Map.update(categories, fun.(entry), [entry], &[entry|&1])
    end)
  end

end
