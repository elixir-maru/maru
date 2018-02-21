alias Maru.Resource

defmodule Resource.Helper do
  alias Resource.MaruPlug

  def set_version(version, %Macro.Env{module: module}) do
    resource = Module.get_attribute(module, :resource)
    new_resource = %{resource | version: version}
    Module.put_attribute(module, :resource, new_resource)
  end

  def push_path(path, %Macro.Env{module: module}) when is_list(path) do
    %{path: orig_path} = resource = Module.get_attribute(module, :resource)

    new_resource = %{
      resource
      | path: orig_path ++ path
    }

    Module.put_attribute(module, :resource, new_resource)
  end

  def push_plug(plug, %Macro.Env{module: module}) do
    %{plugs: plugs} = resource = Module.get_attribute(module, :resource)

    new_resource = %{
      resource
      | plugs: MaruPlug.merge(plugs, plug)
    }

    Module.put_attribute(module, :resource, new_resource)
  end

  @doc "merge mounted routes to current scope."
  def mount(mounted_module, %Macro.Env{module: module} = env) do
    resource = Module.get_attribute(module, :resource)

    Enum.each(mounted_module.__routes__(), fn mounted_route ->
      if not is_nil(resource.version) and not is_nil(mounted_route.version) do
        raise "can't mount a versional router to another versional router"
      end

      versioning_path = (is_nil(resource.version) && []) || [{:version}]

      mounted =
        %{
          mounted_route
          | version: mounted_route.version || resource.version,
            path: versioning_path ++ resource.path ++ mounted_route.path,
            parameters: resource.parameters ++ mounted_route.parameters
        }
        |> Maru.Builder.Pipeline.after_mount(mounted_module, env)
        |> Maru.Builder.Exception.after_mount(mounted_module, env)

      Module.put_attribute(module, :mounted, mounted)
    end)
  end

  @doc """
  Generate endpoint called within route block.
  """
  def dispatch(ep) do
    conn =
      if ep.has_params do
        quote do
          %Plug.Conn{
            private: %{
              maru_params: var!(params)
            }
          } = var!(conn)
        end
      else
        quote do: var!(conn)
      end

    quote do
      def endpoint(unquote(conn), unquote(ep.func_id)) do
        unquote(ep.block)
      end
    end
  end

  def endpoint(ep, %Macro.Env{module: module} = env) do
    resource = Module.get_attribute(module, :resource)
    version = (is_nil(resource.version) && []) || [{:version}]

    func_id = make_func_id(ep.method, resource.version, resource.path ++ ep.path)

    method_context = %{
      block: ep.block,
      method: ep.method,
      version: resource.version,
      path: version ++ resource.path ++ ep.path,
      helpers: resource.helpers,
      plugs: MaruPlug.merge(resource.plugs, MaruPlug.pop(env)),
      func_id: func_id
    }

    Module.put_attribute(module, :method_context, method_context)

    router =
      method_context
      |> Map.take([:method, :version, :path, :helpers, :plugs])
      |> Map.merge(%{module: module, func_id: func_id})

    Module.put_attribute(module, :router, struct(Maru.Router, router))

    Maru.Builder.Parameter.before_parse_router(env)
    Maru.Builder.Description.before_parse_router(env)

    router = Module.get_attribute(module, :router)
    Module.put_attribute(module, :routes, router)

    endpoint =
      Module.get_attribute(module, :method_context)
      |> Map.take([:block, :func_id])
      |> Map.put(:has_params, [] != router.parameters)

    Module.put_attribute(module, :endpoints, struct(Maru.Resource.Endpoint, endpoint))
  end

  defp make_func_id(method, version, path) do
    method = method |> to_string |> String.upcase()
    version = (is_nil(version) && "_") || version

    path =
      path
      |> Enum.map(fn
        atom when is_atom(atom) -> ":#{atom}"
        string when is_binary(string) -> string
      end)
      |> Enum.join("/")

    :"#{version}.#{method}.#{path}"
  end
end
