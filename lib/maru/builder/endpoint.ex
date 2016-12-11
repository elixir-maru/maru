defmodule Maru.Builder.Endpoint do
  @moduledoc """
  Generate endpoints of maru router.
  """

  @doc """
  Generate endpoint called within route block.
  """
  def dispatch(ep) do
    conn =
      if ep.has_params do
        quote do
          %Plug.Conn{
            private: %{
              maru_params: var!(params)
            }
          } = var!(conn)
        end
      else
        quote do: var!(conn)
      end
    quote do
      def endpoint(unquote(conn), unquote(ep.func_id)) do
        unquote(ep.block)
      end
    end
  end

end
