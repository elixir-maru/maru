defmodule Maru.Builder.Namespaces do
  @moduledoc """
  Namespace DSLs for parsing router.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Resource
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
      Resource.push_param(Parameter.pop)
      unquote(block)
      Resource.restore(r)
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, [do: block]) do
    options = options |> Params.escape_options
    quote do
      p = Parameter.snapshot
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Parameter.push(%{
        Params.parse_options(unquote options) |
        attr_name: unquote(param),
        required: true,
        children: []
      })
      Resource.push_param(Parameter.pop)
      unquote(block)
      Resource.restore(r)
      Parameter.restore(p)
    end
  end

end
