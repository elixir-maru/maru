defmodule Maru.Helper do
  defmacro __using__(_) do
    quote do
      use Maru.Helpers.Response
      import unquote(__MODULE__)
    end
  end
end
