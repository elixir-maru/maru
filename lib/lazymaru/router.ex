defmodule Lazymaru.Router do
  defmacro __using__(_) do
    quote do
      use Lazymaru.Builder
    end
  end

  defmodule Resource do
    defstruct path: [], params: %{}
  end
end
