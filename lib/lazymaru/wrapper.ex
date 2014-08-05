defmodule Lazymaru.Wrapper do
  defmacro __using__(_) do
    quote do
      use LazyHelper.Response
      import unquote(__MODULE__)

      def init(opts), do: opts
      defoverridable [init: 1]
    end
  end
end