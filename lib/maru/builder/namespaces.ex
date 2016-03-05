defmodule Maru.Builder.Namespaces do
  @moduledoc """
  Namespace DSLs for parsing router.
  """

  alias Maru.Builder.Params
  alias Maru.Router.Resource
  alias Maru.Router.Path, as: MaruPath

  @namespaces [:namespace, :group, :resource, :resources, :segment]

  for namespace <- @namespaces do
    @doc "Namespace alias #{namespace}."
    defmacro unquote(namespace)([do: block]), do: block
    defmacro unquote(namespace)(path, [do: block]) do
      path = path |> MaruPath.split
      quote do
        %Resource{path: path} = resource = @resource
        @resource %{resource | path: path ++ unquote(path)}
        unquote(block)
        @resource resource
      end
    end
  end

  @doc "Special namespace which save path to param list."
  defmacro route_param(param, [do: block]) do
    quote do
      %Resource{path: path, param_context: param_context} = resource = @resource
      @resource %{ resource |
                   path: path ++ [unquote(param)],
                   param_context: param_context ++ @param_context
                 }
      @param_context []
      unquote(block)
      @resource resource
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, [do: block]) do
    quote do
      %Resource{path: path, param_context: param_context} = resource = @resource
      @resource %{ resource |
                   path: path ++ [unquote(param)],
                   param_context: param_context ++ @param_context
                 }
      param_context = @param_context
      @param_context [
        Params.parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(param),
          required: true,
          children: []
        })
      ]
      unquote(block)
      @param_context param_context
      @resource resource
    end
  end

end
