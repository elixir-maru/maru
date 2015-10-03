defmodule Maru.Coercer do
  @moduledoc false

  @doc false
  def parse(value, nil) do
    value
  end

  def parse(value, coercer) when is_function(coercer) do
    coercer.(value)
  end

  def parse(value, coercer) when is_atom(coercer) do
    module = coercer |> Atom.to_string |> Maru.Utils.upper_camel_case |> String.to_atom
    m = [ Maru.Coercer, module] |> Module.safe_concat
    m.from(value)
  end

  defmodule Json do
    @moduledoc """
    coerce param with json
    """

    @doc false
    def from(s), do: s |> Poison.decode!
  end

  defmodule Base64 do
    @moduledoc """
    coerce param with base64
    """

    @doc false
    def from(s), do: s |> Base.decode64!
  end
end
