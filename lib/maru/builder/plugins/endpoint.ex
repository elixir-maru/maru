alias Maru.Builder.Plugins.Endpoint

defmodule Endpoint do
  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :endpoints, accumulate: true
    end
  end

  def callback_build_method(%{module: module}) do
    endpoint = Module.get_attribute(module, :context)
    endpoint =
      endpoint
      |> Map.take([:block, :func_id])
      |> Map.put(:has_params, [] != endpoint.parameters)
    Module.put_attribute(module, :endpoints, struct(Maru.Struct.Endpoint, endpoint))
  end

  def callback_before_compile(%Macro.Env{module: module}=env) do
    quoted =
      Module.get_attribute(module, :endpoints)
      |> Enum.reverse
      |> Enum.map(&Endpoint.Helper.dispatch/1)

    Module.eval_quoted(env, quoted)
  end

end
