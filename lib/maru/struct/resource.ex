defmodule Maru.Struct.Resource do
  @moduledoc false

  alias Maru.Struct.Resource
  alias Maru.Struct.Plug, as: MaruPlug

  defstruct path:       [],
            parameters: [],
            plugs:      [],
            helpers:    [],
            version:    nil

  @doc "make snapshot for current scope."
  defmacro snapshot do
    quote do
      @resource
    end
  end

  @doc "restore current scope by an snapshot."
  defmacro restore(value) do
    quote do
      @resource unquote(value)
    end
  end

  @doc "push path to current scope."
  defmacro push_path(value) when is_list(value) do
    quote do
      %Resource{path: path} = resource = @resource
      @resource %{
        resource |
        path: path ++ unquote(value),
      }
    end
  end

  defmacro push_path(value) do
    quote do
      %Resource{path: path} = resource = @resource
      @resource %{
        resource |
        path: path ++ [unquote(value)],
      }
    end
  end

  @doc "push parameter to current scope."
  defmacro push_param(value) do
    quote do
      %Resource{parameters: params} = resource = @resource
      parameters =
        case unquote(value) do
          v when is_list(v) -> params ++ v
          v                 -> params ++ [v]
        end
      @resource %{ resource | parameters: parameters }
    end
  end

  @doc "push plug to current scope."
  defmacro push_plug(value) do
    quote do
      %Resource{plugs: plugs} = resource = @resource
      @resource %{
        resource |
        plugs: MaruPlug.merge(plugs, unquote(value)),
      }
    end
  end

  @doc "get endpoint version of current scope ."
  defmacro get_version do
    quote do
      @resource.version
    end
  end

  @doc "set endpoint version of current scope ."
  defmacro set_version(value) do
    quote do
      @resource %{
        @resource |
        version: unquote(value)
      }
    end
  end

end
