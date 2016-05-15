defmodule Maru.Builder.Endpoint do
  @moduledoc """
  Generate endpoints of maru router.
  """

  @doc """
  Generate endpoint called within route block.
  """
  def dispatch(ep) do
    quote do
      def endpoint(var!(conn), unquote(ep.func_id)) do
        unquote(ep.block)
      end
    end
  end

end
