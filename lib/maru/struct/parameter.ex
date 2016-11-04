 defmodule Maru.Struct.Parameter do
  @moduledoc false

  defstruct information: nil,
            runtime: nil

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

defmodule Maru.Struct.Parameter.Information do
  @moduledoc false

  defstruct attr_name: nil,
            param_key: nil,
            desc:      nil,
            type:      nil,
            default:   nil,
            required:  true,
            children:  []

end

defmodule Maru.Struct.Parameter.Runtime do
  @moduledoc false

  defstruct attr_name:     nil,
            param_key:     nil,
            children:      [],
            nested:        nil,
            blank_func:    nil,
            parser_func:   nil,
            validate_func: nil

end
