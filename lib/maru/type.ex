defmodule Maru.Type do
  defmacro __using__(_) do
    quote do
      def arguments do
        []
      end

      def parse(input, _) do
        input
      end

      defoverridable arguments: 0, parse: 2
    end
  end
end
