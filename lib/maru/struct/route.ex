defmodule Maru.Struct.Route do
  @moduledoc false

  alias Maru.Struct.Plug, as: MaruPlug

  defstruct method:     nil,
            path:       [],
            version:    nil,
            desc:       nil,
            parameters: [],
            helpers:    [],
            plugs:      [],
            module:     nil,
            func_id:    nil,
            mount_link: []

  @doc "push an endpoint to current scope."
  defmacro push(%__MODULE__{}=value) do
    quote do
      @routes @routes ++ [unquote(value)]
    end
  end

  @doc "merge mounted routes to current scope."
  def merge(resource, plugs, module, %__MODULE__{}=route) do
    if not is_nil(resource.version) and not is_nil(route.version) do
      raise "can't mount a versional router to another versional router"
    end
    versioning_path = is_nil(resource.version) && [] || [{:version}]
    %{ route |
       version:    route.version       || resource.version,
       path:       versioning_path     ++ resource.path ++ route.path,
       parameters: resource.parameters ++ route.parameters,
       plugs:      resource.plugs      |> MaruPlug.merge(plugs) |> MaruPlug.merge(route.plugs),
       mount_link: route.mount_link ++ [module],
     }
  end

end
