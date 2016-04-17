defmodule Maru.Builder.Exceptions do
  @moduledoc """
  Handle exceptions of current router.
  """

  @doc false
  defmacro rescue_from(:all, [as: error_var], [do: block]) do
    quote do
      @exceptions {:all, unquote(Macro.escape error_var), unquote(Macro.escape block)}
    end
  end

  defmacro rescue_from(error, [as: error_var], [do: block]) do
    quote do
      @exceptions {unquote(error), unquote(Macro.escape error_var), unquote(Macro.escape block)}
    end
  end

  @doc false
  defmacro rescue_from(:all, [do: block]) do
    quote do
      @exceptions {:all, unquote(Macro.escape block)}
    end
  end

  defmacro rescue_from(error, [do: block]) do
    quote do
      @exceptions {unquote(error), unquote(Macro.escape block)}
    end
  end


  @doc false
  def make_rescue_block({:all, block}) do
    quote do
      _ ->
        unquote(block)
    end
  end

  def make_rescue_block({error, block}) do
    quote do
      unquote(error) ->
        unquote(block)
    end
  end

  @doc false
  def make_rescue_block({:all, error_var, block}) do
    quote do
      unquote(error_var) ->
        unquote(block)
    end
  end

  def make_rescue_block({error, error_var, block}) do
    quote do
      unquote(error_var) in unquote(error) ->
        unquote(block)
    end
  end

end
