alias Maru.Resource.MaruPlug
alias Maru.Builder.Pipeline

defmodule Pipeline do
  defmacro __using__(_) do
    quote do
      @plugs []
      import Pipeline.DSLs, only: [pipeline: 1]
    end
  end

  def after_mount(%{plugs: mounted_plugs} = mounted_route, _module, %Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    resource = Module.get_attribute(module, :resource)

    %{
      mounted_route
      | plugs: resource.plugs |> MaruPlug.merge(plugs) |> MaruPlug.merge(mounted_plugs)
    }
  end

  def before_parse_namespace(%Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    Module.put_attribute(module, :plugs, [])

    resource = Module.get_attribute(module, :resource)
    new_plugs = MaruPlug.merge(resource.plugs, plugs)
    Module.put_attribute(module, :resource, %{resource | plugs: new_plugs})
  end
end
