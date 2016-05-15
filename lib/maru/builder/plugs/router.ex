defmodule Maru.Builder.Plugs.Router do
  @moduledoc """
  Fetch and merge all routes and expose them by `__routes__` function.
  """

  @doc false
  def compile(%Macro.Env{module: module}) do
    extend_opts = Module.get_attribute(module, :extend)
    routes      = Module.get_attribute(module, :routes) ++
                  Module.get_attribute(module, :mounted)
    extended    = Maru.Builder.Extend.take_extended(routes, extend_opts)
    routes      = routes ++ extended

    endpoints_block =
      Module.get_attribute(module, :endpoints)
      |> Enum.map(&Maru.Builder.Endpoint.dispatch/1)

    quote do
      def __routes__, do: unquote(Macro.escape(routes))
      unquote(endpoints_block)
    end
  end

end
