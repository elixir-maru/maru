defmodule Maru.Builder.Methods do
  @moduledoc """
  Method DSLs for parsing router.
  """

  alias Maru.Struct.Resource
  alias Maru.Struct.Parameter
  alias Maru.Struct.Endpoint
  alias Maru.Struct.Route
  alias Maru.Struct.Plug, as: MaruPlug
  alias Maru.Builder.Path, as: MaruPath

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  for method <- @methods do
    @doc "Handle #{method} method."
    defmacro unquote(method)(path \\ "", [do: block]) do
      %{ method: unquote(method) |> to_string |> String.upcase,
         path:   path |> MaruPath.split,
         block:  block |> Macro.escape,
       } |> endpoint
    end
  end

  @doc "Handle all method."
  defmacro match(path \\ "", [do: block]) do
    %{ method: Macro.var(:_, nil) |> Macro.escape,
       path:   path |> MaruPath.split,
       block:  block |> Macro.escape,
     } |> endpoint
  end

  defp endpoint(ep) do
    quote do
      resource = Resource.snapshot
      version =
        if is_nil(resource.version) do
          [] else [{:version}]
        end
      @endpoints %Endpoint{
        func_id: @func_id,
        block:   unquote(ep.block)
      }
      @routes %Route{
        desc:       @desc,
        method:     unquote(ep.method),
        version:    resource.version,
        path:       version ++ resource.path ++ unquote(ep.path),
        parameters: resource.parameters ++ Parameter.pop,
        helpers:    resource.helpers,
        plugs:      MaruPlug.merge(resource.plugs, MaruPlug.pop),
        module:     __MODULE__,
        func_id:    @func_id,
        mount_link: [__MODULE__],
      }
      @desc nil
      @func_id @func_id + 1
    end
  end


end
