defmodule Maru.Router do
  @moduledoc false

  defstruct [
              method: nil,
              path: [],
              version: nil,
              parameters: [],
              helpers: [],
              plugs: [],
              module: nil,
              func_id: nil
            ] ++
              Maru.Builder.Exception.router_struct() ++ Maru.Builder.Description.router_struct()

  defmacro __using__(opts) do
    quote do
      use Maru.Builder, unquote(opts)
    end
  end
end
