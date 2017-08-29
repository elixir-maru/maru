defmodule Maru.Builder.Namespaces do
  @moduledoc """
  Namespace DSLs for parsing router.
  """

  alias Maru.Struct.Resource
  alias Maru.Builder.Path, as: MaruPath

  @namespaces [:namespace, :group, :resource, :resources, :segment]

  for namespace <- @namespaces do
    @doc "Namespace alias #{namespace}."
    defmacro unquote(namespace)([do: block]), do: block
    defmacro unquote(namespace)(path, [do: block]) do
      path = path |> MaruPath.split
      namespace = unquote(namespace)
      quote do
        @namespace_context %{
          namespace: unquote(namespace),
          parameter: unquote(path),
          options:   [],
        }
        r = Resource.snapshot
        Resource.push_path(unquote(path))
        Maru.Builder.Plugins.Parameter.callback_namespace(__ENV__)
        Maru.Builder.Plugins.Pipeline.callback_namespace(__ENV__)
        unquote(block)
        Resource.restore(r)
      end
    end
  end

  @doc "Special namespace which save path to param list."
  defmacro route_param(param, [do: block]) when is_atom(param) do
    quote do
      @namespace_context %{
        namespace: :route_param,
        parameter: unquote(param),
        options:   [],
      }
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Maru.Builder.Plugins.Pipeline.callback_namespace(__ENV__)
      Maru.Builder.Plugins.Parameter.callback_namespace(__ENV__)
      unquote(block)
      Resource.restore(r)
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, [do: block]) when is_atom(param) do
    options = options |> Macro.escape
    quote do
      @namespace_context %{
        namespace: :route_param,
        parameter: unquote(param),
        options:   unquote(options),
      }
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Maru.Builder.Plugins.Pipeline.callback_namespace(__ENV__)
      Maru.Builder.Plugins.Parameter.callback_namespace(__ENV__)
      unquote(block)
      Resource.restore(r)
    end
  end

end
