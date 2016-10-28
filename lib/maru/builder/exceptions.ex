defmodule Maru.Builder.Exceptions do
  @moduledoc """
  Handle exceptions of current router.
  """

  alias Maru.Struct.Exception

  @doc false
  defmacro rescue_from(errors, [as: error_var], [do: block]) do
    errors = format_errors(errors)
    quote do
      @exceptions %Exception{
        errors:    unquote(errors),
        error_var: unquote(Macro.escape error_var),
        block:     unquote(Macro.escape block),
      }
    end
  end

  @doc false
  defmacro rescue_from(errors, [do: block]) do
    errors = format_errors(errors)
    quote do
      @exceptions %Exception{
        errors: unquote(errors),
        block:  unquote(Macro.escape block),
      }
    end
  end

  defmacro rescue_from(errors, [with: function]) do
    errors = format_errors(errors)
    quote do
      @exceptions %Exception{
        errors:    unquote(errors),
        error_var: Macro.var(:maru_exception, nil),
        function:  unquote(function),
      }
    end
  end

  defp format_errors(:all),  do: :all
  defp format_errors(errors)
  when is_list(errors),      do: errors
  defp format_errors(error), do: [error]

  @doc false
  def make_rescue_block(%Exception{}=exception) do
    var   = make_variable(exception.errors, exception.error_var)
    block = make_block(exception.function, exception.error_var, exception.block)
    quote do
      unquote(var) -> unquote(block)
    end
  end

  defp make_variable(:all,   nil), do: (quote do _ end)
  defp make_variable(:all,   var), do: var
  defp make_variable(errors, nil), do: errors
  defp make_variable(errors, var), do: (quote do unquote(var) in unquote(errors) end)

  defp make_block(nil, _, block) do
    quote do
      var!(conn) = Maru.Helpers.Response.get_maru_conn
      unquote(block)
    end
  end

  defp make_block(function, var, nil) do
    quote do
      unquote(function)(Maru.Helpers.Response.get_maru_conn, unquote(var))
    end
  end

end
