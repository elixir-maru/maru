defmodule Maru.Struct.Parameter do
  @moduledoc false

  defstruct attr_name:   nil,
            source:      nil,
            default:     nil,
            desc:        nil,
            required:    true,
            children:    [],
            nested:      nil,
            parsers:     nil,
            validators:  []

  @doc "make snapshot for current scope."
  defmacro snapshot do
    quote do
      @parameters
    end
  end

  @doc "restore current scope by an snapshot."
  defmacro restore(value) do
    quote do
      @parameters unquote(value)
    end
  end

  @doc "push parameters to current scope."
  defmacro push(value) when is_list(value) do
    quote do
      @parameters @parameters ++ unquote(value)
    end
  end

  defmacro push(value) do
    quote do
      @parameters @parameters ++ [unquote(value)]
    end
  end

  @doc "return snapshot and clean current parameter stack."
  defmacro pop do
    quote do
      try do
        @parameters
      after
        @parameters []
      end
    end
  end

end
