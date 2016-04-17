defmodule Maru.Router do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Maru.Builder
    end
  end

end
