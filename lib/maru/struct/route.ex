defmodule Maru.Struct.Route do
  @moduledoc false

  defstruct [
    method:     nil,
    path:       [],
    version:    nil,
    parameters: [],
    helpers:    [],
    plugs:      [],
    module:     nil,
    func_id:    nil,
  ]
  ++ Maru.Builder.Plugins.Exception.route_struct()
  ++ Maru.Builder.Plugins.Description.route_struct()

  @doc "push an endpoint to current scope."
  defmacro push(%__MODULE__{}=value) do
    quote do
      @routes @routes ++ [unquote(value)]
    end
  end

  @doc "merge mounted routes to current scope."
  def merge(resource, module, %__MODULE__{}=route, env) do
    if not is_nil(resource.version) and not is_nil(route.version) do
      raise "can't mount a versional router to another versional router"
    end
    versioning_path = is_nil(resource.version) && [] || [{:version}]
    %{ route |
       version:    route.version       || resource.version,
       path:       versioning_path     ++ resource.path ++ route.path,
       parameters: resource.parameters ++ route.parameters,
     }
     |> Maru.Builder.Plugins.Pipeline.callback_mount(env)
     |> Maru.Builder.Plugins.Exception.callback_mount(module, env)
  end

end
