defmodule Lazymaru.Server do
  defmacro __using__(_) do
    quote do
      use Plug.Builder
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_) do
    quote do
      def start do
        :application.start(:crypto)
        :application.start(:ranch)
        :application.start(:cowlib)
        :application.start(:cowboy)
        Plug.Adapters.Cowboy.http __MODULE__, [], [port: @port]
      end
    end
  end


  defmacro port(port_num) do
    quote do
      @port unquote(port_num)
    end
  end

end