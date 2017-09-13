alias Maru.Resource
alias Maru.Struct.Plug, as: MaruPlug

defmodule Resource.Helper do
  def set_version(version, %Macro.Env{module: module}) do
    resource = Module.get_attribute(module, :resource)
    new_resource = %{ resource | version: version }
    Module.put_attribute(module, :resource, new_resource)
  end


  def push_path(path, %Macro.Env{module: module}) when is_list(path) do
    %{path: orig_path} = resource = Module.get_attribute(module, :resource)
    new_resource = %{
      resource |
      path: orig_path ++ path,
    }
    Module.put_attribute(module, :resource, new_resource)
  end


  def push_plug(plug, %Macro.Env{module: module}) do
    %{plugs: plugs} = resource = Module.get_attribute(module, :resource)
    new_resource = %{
      resource |
      plugs: MaruPlug.merge(plugs, plug),
    }
    Module.put_attribute(module, :resource, new_resource)
  end
end
