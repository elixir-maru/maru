defmodule Maru.Builder.Methods do
  alias Maru.Router.Endpoint
  alias Maru.Router.Path, as: MaruPath

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  for method <- @methods do
    defmacro unquote(method)(path \\ "", [do: block]) do
      %{ method: unquote(method) |> to_string |> String.upcase,
         path: path |> MaruPath.split,
         block: block |> Macro.escape,
       } |> endpoint
    end
  end

  defmacro match(path \\ "", [do: block]) do
    %{ method: Macro.var(:_, nil) |> Macro.escape,
       path: path |> MaruPath.split,
       block: block |> Macro.escape,
     } |> endpoint
  end

  defp endpoint(ep) do
    quote do
      @endpoints %Endpoint{
        desc: @desc,
        method: unquote(ep.method),
        version: @version,
        path: @resource.path ++ unquote(ep.path),
        param_context: @resource.param_context ++ @param_context,
        block: unquote(ep.block),
      }
      @param_context []
      @desc nil
    end
  end
end
