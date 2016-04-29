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
      @plugs unquote(__MODULE__).merge(@plugs, unquote(value))
    end
  end

  defmacro push(value) do
    quote do
      @plugs unquote(__MODULE__).merge(@plugs, [unquote(value)])
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

  @doc "merge and override plugs."
  def merge(plugs, %__MODULE__{}=pipeline) do
    merge(plugs, [pipeline])
  end
  def merge(plugs, pipelines) do
    Enum.reduce(pipelines, plugs, fn x, acc ->
      do_merge(acc, x, [])
    end)
  end

  defp do_merge([], plug, result) do
    result ++ [plug]
  end
  defp do_merge([%__MODULE__{name: nil}=h | t], plug, result) do
    do_merge(t, plug, result ++ [h])
  end
  defp do_merge([%__MODULE__{name: n} | t], %__MODULE__{name: n}=plug, result) do
    result ++ [plug] ++ t
  end
  defp do_merge([h | t], plug, result) do
    do_merge(t, plug, result ++ [h])
  end

end
