defmodule Maru.Builder.Plugs.Router do
  @moduledoc """
  Fetch and merge all endpoints and expose them by `__endpoints__` function.
  """

  @doc false
  def compile(%Macro.Env{module: module}) do
    extend_opts = Module.get_attribute(module, :extend)
    endpoints   = Module.get_attribute(module, :endpoints) ++
                  Module.get_attribute(module, :mounted)
    extended    = Maru.Builder.Extend.take_extended(endpoints, extend_opts)
    endpoints   = endpoints ++ extended

    quote do
      def __endpoints__, do: unquote(Macro.escape(endpoints))
    end
  end

end
