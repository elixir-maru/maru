defmodule Lazymaru.Helper do
  defmacro __using__(_) do
    quote do
      use Lazymaru.Helpers.Response
      import unquote(__MODULE__)
    end
  end
end
