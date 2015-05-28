defmodule Maru.Middleware do
  defmacro __using__(_) do
    quote do
      import Maru.Helpers.Response

      def init(opts), do: opts
      def call(conn, _opts), do: conn
      defoverridable [init: 1, call: 2]
    end
  end
end
