defmodule Maru.Helpers.Params do
  @moduledoc """
  Maru helper for shared params.
  """

  @doc """
  Save shared param to module attribute.
  """
  defmacro params(name, [do: block]) do
    quote do
      @shared_params unquote({name, block |> Macro.escape})
    end
  end
end
