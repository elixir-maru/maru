defmodule Lazymaru.ParamType do
  defmodule Term do
    def from(any), do: any
  end

  defmodule String do
    def from(s), do: s |> to_string
  end


  defmodule Integer do
    def from(s), do: s |> to_string |> Elixir.String.to_integer
  end


  defmodule Float do
    def from(s) when is_float(s), do: s
    def from(s) when is_integer(s), do: :erlang.float(s)
    def from(s) do
      cond do
        Regex.match?(~r/^[0-9]+\.[0-9]+$/, s) -> s |> Elixir.String.to_float
        Regex.match?(~r/^[0-9]+$/, s) -> "#{s}.0" |> Elixir.String.to_float
      end
    end
  end


  defmodule Boolean do
    def from(s) when is_boolean(s), do: s
    def from(nil), do: false
    def from("false"), do: false
    def from("true"), do: true
  end


  defmodule CharList do
    def from(s), do: s |> to_char_list
  end


  defmodule Atom do
    def from(s) when is_atom(s), do: s
    def from(s), do: s |> to_string |> Elixir.String.to_existing_atom
  end


  defmodule File do
    def from(%Plug.Upload{}=f), do: f
  end

  defmodule List do
    def from(list) when is_list(list), do: list
  end

  defmodule Map do
    def from(map) when is_map(map), do: map
  end
end
