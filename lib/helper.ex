defmodule Lazymaru.Helper do
  defmacro __using__(_) do
    quote do
      use LazyHelper.Response
      import unquote(__MODULE__)
    end
  end
end