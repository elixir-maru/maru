defmodule Maru.Helpers.Params do
  defmacro params(name, [do: block]) do
    quote do
      @shared_params unquote({name, block |> Macro.escape})
    end
  end
end
