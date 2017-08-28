defmodule Maru.Builder.Methods do
  @moduledoc """
  Method DSLs for parsing router.
  """

  alias Maru.Struct.{Resource, Parameter}
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
      parameters = resource.parameters ++ Parameter.pop

      @context %{
        block:      unquote(ep.block),
        method:     unquote(ep.method),
        version:    resource.version,
        path:       version ++ resource.path ++ unquote(ep.path),
        parameters: parameters,
        helpers:    resource.helpers,
        plugs:      MaruPlug.merge(resource.plugs, MaruPlug.pop),
        func_id:    @func_id,
      }

      @func_id @func_id + 1

      Maru.Builder.Plugins.Route.callback_build_method(__ENV__)
    end
  end


end
