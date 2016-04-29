defmodule Maru.Coercion do

  defmacro __using__(_) do
    quote do
      def arguments do
        []
      end

      def coerce(input, _) do
        input
      end

      defoverridable [arguments: 0, coerce: 2]
    end
  end

end
