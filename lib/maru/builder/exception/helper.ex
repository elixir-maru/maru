alias Maru.Builder.Exception

defmodule Exception.Helper do
  @moduledoc """
  Handle exceptions of current router.
  """

  @doc false
  def make_rescue_block(%Exception{} = exception) do
    var = make_variable(exception.errors, exception.error_var)
    block = make_block(exception.function, exception.error_var, exception.block)

    quote do
      unquote(var) -> unquote(block)
    end
  end

  defp make_variable(:all, nil),
    do:
      (quote do
         _
       end)

  defp make_variable(:all, var), do: var
  defp make_variable(errors, nil), do: errors

  defp make_variable(errors, var),
    do:
      (quote do
         unquote(var) in unquote(errors)
       end)

  defp make_block(nil, _, block) do
    quote do
      var!(conn) = Maru.Response.get_maru_conn()
      unquote(block)
    end
  end

  defp make_block(function, var, nil) do
    quote do
      unquote(function)(Maru.Response.get_maru_conn(), unquote(var))
    end
  end
end
