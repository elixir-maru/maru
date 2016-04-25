defmodule Maru.Struct.Plug do
  @moduledoc false

  defstruct name:    nil,
            plug:    nil,
            options: nil,
            guards:  true

  @doc "make snapshot for current scope."
  defmacro snapshot do
    quote do
      @plugs
    end
  end

  @doc "restore current scope by an snapshot."
  defmacro restore(value) do
    quote do
      @plugs unquote(value)
    end
  end

  @doc "push plugs to current scope."
  defmacro push(value) when is_list(value) do
    quote do
      @plugs @plugs ++ unquote(value)
    end
  end

  defmacro push(value) do
    quote do
      @plugs @plugs ++ [unquote(value)]
    end
  end

  @doc "return snapshot and clean current plugs stack."
  defmacro pop do
    quote do
      try do
        @plugs
      after
        @plugs []
      end
    end
  end

  def merge(resource_plugs, pipelines) do
    resource_plugs ++ pipelines
  end
end
