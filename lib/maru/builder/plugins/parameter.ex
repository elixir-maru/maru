alias Maru.Builder.Plugins.Parameter

defmodule Parameter.Information do
  @moduledoc false

  defstruct attr_name: nil,
            param_key: nil,
            desc:      nil,
            type:      nil,
            default:   nil,
            required:  true,
            children:  []

end

defmodule Parameter.Runtime do
  @moduledoc false

  defstruct attr_name:     nil,
            param_key:     nil,
            children:      [],
            nested:        nil,
            blank_func:    nil,
            parser_func:   nil,
            validate_func: nil

end

defmodule Parameter do
  defstruct information: nil,
            runtime: nil

  defmacro __using__(_) do
    quote do
      @parameters []
      import Parameter.DSLs, only: [params: 1]
    end
  end

  def callback_namespace(%Macro.Env{module: module}) do
    parameters = Module.get_attribute(module, :parameters)
    Module.put_attribute(module, :parameters, [])

    addittion_parameter =
      case Module.get_attribute(module, :namespace_context) do
        %{namespace: :route_param}=context ->
          [ attr_name: context.parameter, required: true,
          ] |> Enum.concat(context.options) |> Parameter.Helper.parse
        _ -> nil
      end

    resource = Module.get_attribute(module, :resource)
    new_parameters = resource.parameters ++ parameters ++ List.wrap(addittion_parameter)
    Module.put_attribute(module, :resource, %{resource | parameters: new_parameters})
  end

  def callback_build_route(%Macro.Env{module: module}) do
    resource = Module.get_attribute(module, :resource)
    parameters = Module.get_attribute(module, :parameters)
    Module.put_attribute(module, :parameters, [])

    route = Module.get_attribute(module, :route)
    Module.put_attribute(module, :route, %{route | parameters: resource.parameters ++ parameters})
  end
end
