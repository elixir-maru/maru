defmodule Maru.Router do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      use Maru.Builder, unquote(opts)
    end
  end

end
