defmodule Maru.Middleware do
  @moduledoc """
  Middleware of maru is a standalone plug with `Maru.Response` helper.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      use Maru.Response

      def init(opts), do: opts
      def call(conn, _opts), do: conn
      defoverridable init: 1, call: 2
    end
  end
end
