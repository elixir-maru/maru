defmodule Maru.Builder.Description do
  @moduledoc """
  Parse and build description block.
  """

  @doc """
  Define detail of description.
  """
  defmacro detail(detail) do
    quote do
      @desc put_in(@desc, [:detail], unquote(detail))
    end
  end

  @doc """
  Define response of description.
  """
  defmacro responses([do: block]) do
    quote do
      @desc put_in(@desc, [:responses], [])
      unquote(block)
    end
  end

  @doc """
  Define status within response.
  """
  defmacro status(code, options) do
    desc = Keyword.get(options, :desc)
    status = %{code: code, description: desc} |> Macro.escape
    quote do
      @desc update_in(@desc, [:responses], &(&1 ++ [unquote(status)]))
    end
  end

end
