defmodule Maru.Builder.Namespaces do
  @moduledoc """
  Namespace DSLs for parsing router.
  """

  alias Maru.Builder.Params
  alias Maru.Router.Param
  alias Maru.Router.Resource
  alias Maru.Router.Path, as: MaruPath

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
      Resource.push_param(Param.pop)
      unquote(block)
      Resource.restore(r)
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, [do: block]) do
    options = options |> Params.escape_options
    quote do
      p = Param.snapshot
      r = Resource.snapshot
      Resource.push_path(unquote(param))
      Param.push(%{
        Params.parse_options(unquote options) |
        attr_name: unquote(param),
        required: true,
        children: []
      })
      Resource.push_param(Param.pop)
      unquote(block)
      Resource.restore(r)
      Param.restore(p)
    end
  end

end
