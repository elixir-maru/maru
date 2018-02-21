alias Maru.Builder.Exception

defmodule Exception.DSLs do
  @moduledoc """
  Handle exceptions of current router.
  """

  @doc false
  defmacro rescue_from(errors, [as: error_var], do: block) do
    errors = format_errors(errors)

    quote do
      @exceptions %Exception{
        errors: unquote(errors),
        error_var: unquote(Macro.escape(error_var)),
        block: unquote(Macro.escape(block))
      }
    end
  end

  @doc false
  defmacro rescue_from(errors, do: block) do
    errors = format_errors(errors)

    quote do
      @exceptions %Exception{
        errors: unquote(errors),
        block: unquote(Macro.escape(block))
      }
    end
  end

  defmacro rescue_from(errors, with: function) do
    errors = format_errors(errors)

    quote do
      @exceptions %Exception{
        errors: unquote(errors),
        error_var: Macro.var(:maru_exception, nil),
        function: unquote(function)
      }
    end
  end

  defp format_errors(:all), do: :all

  defp format_errors(errors)
       when is_list(errors),
       do: errors

  defp format_errors(error), do: [error]
end
