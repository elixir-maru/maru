defmodule Lazymaru.Sock do

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro path(p) do
    quote do
      def path do
        unquote(p)
      end
    end
  end

  # # TODO  connected or init
  # defmacro connect([do: block]) do
  #   quote do
  #     def websocket_init(_, var!(unquote :req), _) do
  #       unquote(block)
  #       {:ok, req, nil}
  #     end
  #   end
  # end

  defmacro recv(data, [do: block]) do
    quote do
      def websocket_handle(unquote(data), var!(unquote :req), var!(unquote :state)) do
        unquote(block)
        {:ok, req, state}
      end
    end
  end

  defmacro info(data, [do: block]) do
    quote do
      def websocket_info(unquote(data), var!(unquote :req), var!(unquote :state)) do
        unquote(block)
        {:ok, req, state}
      end
    end
  end

  defmacro reply(msg) do
    quote do
      send(self, {:reply, unquote(msg)})
    end
  end

  # defmacro closed([do: block]) do
  #   quote do
  #     def do_sock(var!(unquote :req), :closed, var!(unquote :state)) do
  #       unquote(block)
  #     end
  #   end
  # end

end