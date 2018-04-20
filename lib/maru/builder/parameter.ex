alias Maru.Builder.Parameter

defmodule Parameter.Information do
  @moduledoc false

  defstruct attr_name: nil,
            param_key: nil,
            desc: nil,
            type: nil,
            default: nil,
            required: true,
            children: []
end

defmodule Parameter.Runtime do
  @moduledoc false

  defstruct attr_name: nil,
            param_key: nil,
            children: [],
            nested: nil,
            blank_func: nil,
            parser_func: nil,
            validate_func: nil
end

defmodule Parameter do
  defstruct information: nil,
            runtime: nil

  defmacro __using__(_) do
    quote do
      @parameters []
      Module.register_attribute(__MODULE__, :shared_params, accumulate: true)
      import Parameter.DSLs, only: [params: 1, params: 2]
    end
  end

  def using_helper(_) do
    quote do
      Module.register_attribute(__MODULE__, :shared_params, accumulate: true)
      import Parameter.DSLs, only: [params: 2]
    end
  end

  def after_helper(helper_module, %Macro.Env{module: env_module}) do
    Enum.each(
      helper_module.__shared_params__(),
      &Module.put_attribute(env_module, :shared_params, &1)
    )
  end

  def before_parse_namespace(%Macro.Env{module: module}) do
    parameters = Module.get_attribute(module, :parameters)
    Module.put_attribute(module, :parameters, [])

    addittion_parameter =
      case Module.get_attribute(module, :namespace_context) do
        %{namespace: :route_param} = context ->
          [attr_name: context.parameter, required: true]
          |> Enum.concat(context.options)
          |> Parameter.Helper.parse()

        _ ->
          nil
      end

    resource = Module.get_attribute(module, :resource)
    new_parameters = resource.parameters ++ parameters ++ List.wrap(addittion_parameter)
    Module.put_attribute(module, :resource, %{resource | parameters: new_parameters})
  end

  def before_parse_router(%Macro.Env{module: module}) do
    resource = Module.get_attribute(module, :resource)
    parameters = Module.get_attribute(module, :parameters)
    Module.put_attribute(module, :parameters, [])

    route = Module.get_attribute(module, :router)

    Module.put_attribute(module, :router, %{route | parameters: resource.parameters ++ parameters})
  end

  def before_compile_helper(%Macro.Env{module: module} = env) do
    shared_params =
      for {name, params} <- Module.get_attribute(module, :shared_params) do
        {name, params |> Macro.escape()}
      end

    quoted =
      quote do
        def __shared_params__ do
          unquote(shared_params)
        end
      end

    Module.eval_quoted(env, quoted)
  end
end
