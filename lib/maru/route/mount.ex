alias Maru.Route

defmodule Route.Mount do
  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :mounted, accumulate: true
      import Route.Mount.DSLs
    end
  end
end

defmodule Route.Mount.DSLs do
  @doc """
  Mount another router to current router.
  """
  defmacro mount({_, _, [h | t]}=mod) do
    h = Module.concat([h])
    module =
      __CALLER__.aliases
      |> Keyword.get(h, h)
      |> Module.split
      |> Enum.concat(t)
      |> Module.concat
    try do
      true = {:__routes__, 0} in module.__info__(:functions)
    rescue
      [UndefinedFunctionError, MatchError] ->
        raise """
          #{inspect module} is not an available Maru.Router.
          If you mount it to another module written at the same file,
          make sure this module at the front of the file.
        """
    end

    quote do
      Route.Mount.Helper.mount(unquote(mod), __ENV__)
    end
  end
end

defmodule Route.Mount.Helper do
  @doc "merge mounted routes to current scope."
  def mount(mounted_module, %Macro.Env{module: module}=env) do
    resource = Module.get_attribute(module, :resource)

    Enum.each(mounted_module.__routes__(), fn mounted_route ->
      if not is_nil(resource.version) and not is_nil(mounted_route.version) do
        raise "can't mount a versional router to another versional router"
      end

      versioning_path = is_nil(resource.version) && [] || [{:version}]
      mounted =
        %{ mounted_route |
           version:    mounted_route.version || resource.version,
           path:       versioning_path       ++ resource.path ++ mounted_route.path,
           parameters: resource.parameters   ++ mounted_route.parameters,
        }
        |> Maru.Builder.Pipeline.after_mount(mounted_module, env)
        |> Maru.Builder.Exception.after_mount(mounted_module, env)
      Module.put_attribute(module, :mounted, mounted)
    end)
  end
end
