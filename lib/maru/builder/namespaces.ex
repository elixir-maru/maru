defmodule Maru.Builder.Namespaces do
  @moduledoc """
  Namespace DSLs for parsing router.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Resource
  alias Maru.Struct.Plug, as: MaruPlug
  alias Maru.Builder.Params
  alias Maru.Builder.Path, as: MaruPath

  @namespaces [:namespace, :group, :resource, :resources, :segment]

  for namespace <- @namespaces do
    @doc "Namespace alias #{namespace}."
    defmacro unquote(namespace)([do: block]), do: block
    defmacro unquote(namespace)(path, [do: block]) do
      path = path |> MaruPath.split
      quote do
        r = Resource.snapshot
        Resource.push_path(unquote(path))
        Resource.push_plug(MaruPlug.pop)
        Resource.push_param(Parameter.pop)
        unquote(block)
        Resource.restore(r)
      end
    end
  end

  @doc "Special namespace which save path to param list."
  defmacro route_param(param, [do: block]) do
    quote do
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Resource.push_plug(MaruPlug.pop)
      Resource.push_param(Parameter.pop)
      unquote(block)
      Resource.restore(r)
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, [do: block]) do
    options = options |> Macro.escape
    quote do
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Resource.push_plug(MaruPlug.pop)
      Resource.push_param(Parameter.pop)
      Resource.push_param(%{
        Params.parse_options(unquote options) |
        attr_name: unquote(param),
        required: true,
        children: []
      })
      unquote(block)
      Resource.restore(r)
    end
  end

end
