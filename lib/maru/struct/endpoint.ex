defmodule Maru.Struct.Endpoint do
  @moduledoc false

  alias Maru.Struct.Plug, as: MaruPlug

  defstruct method:     nil,
            path:       [],
            version:    nil,
            desc:       nil,
            parameters: [],
            block:      nil,
            helpers:    [],
            plugs:      [],
            __file__:   nil

  @doc "push an endpoint to current scope."
  defmacro push(%__MODULE__{}=value) do
    quote do
      @endpoints @endpoints ++ [unquote(value)]
    end
  end

  @doc "merge mounted endpoints to current scope."
  def merge(resource, plugs, %__MODULE__{}=ep) do
    if not is_nil(resource.version) and not is_nil(ep.version) do
      raise "can't mount a versional router to another versional router"
    end
    versioning_path = is_nil(resource.version) && [] || [{:version}]
    %{ ep |
       version:    ep.version          || resource.version,
       path:       versioning_path     ++ resource.path ++ ep.path,
       parameters: resource.parameters ++ ep.parameters,
       plugs:      resource.plugs      |> MaruPlug.merge(plugs) |> MaruPlug.merge(ep.plugs),
     }
  end

end
