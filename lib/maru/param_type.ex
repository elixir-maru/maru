defmodule Maru.ParamType do
  defmodule Term do
    @moduledoc """
    Keep param without conversion.
    """

    @doc false
    def from(any), do: any
  end

  defmodule String do
    @moduledoc """
    Convert param to string.
    """

    @doc false
    def from(s), do: s |> to_string
  end


  defmodule Integer do
    @moduledoc """
    Convert param to integer.
    """

    @doc false
    def from(s), do: s |> to_string |> Elixir.String.to_integer
  end


  defmodule Float do
    @moduledoc """
    Convert param to float.
    """

    @doc false
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
    @moduledoc """
    Convert param to boolean.
    """

    @doc false
    def from(s) when is_boolean(s), do: s
    def from(nil), do: false
    def from("false"), do: false
    def from("true"), do: true
  end


  defmodule CharList do
    @moduledoc """
    Convert param to chat list.
    """

    @doc false
    def from(s), do: s |> to_char_list
  end


  defmodule Atom do
    @moduledoc """
    Convert param to existing atom.
    """

    @doc false
    def from(s) when is_atom(s), do: s
    def from(s), do: s |> to_string |> Elixir.String.to_existing_atom
  end


  defmodule File do
    @moduledoc """
    Check param match `Plug.Upload` struct.
    """

    @doc false
    def from(%Plug.Upload{}=f), do: f
  end

  defmodule List do
    @moduledoc """
    Check type of param is list.
    """

    @doc false
    def from(list) when is_list(list), do: list
  end

  defmodule Map do
    @moduledoc """
    Check type of param is map.
    """

    @doc false
    def from(map) when is_map(map), do: map
  end

  defmodule Json do
    @moduledoc """
    Convert param to map from json.
    """

    @doc false
    def from(s), do: s |> Poison.decode!
  end
end
