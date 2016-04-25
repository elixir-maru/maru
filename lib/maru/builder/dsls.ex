defmodule Maru.Builder.DSLs do
  @moduledoc """
  General DSLs for parsing router.
  """

  alias Maru.Struct.Resource
  alias Maru.Struct.Plug, as: MaruPlug
  alias Maru.Builder.Path, as: MaruPath

  @doc """
  Define path prefix of current router.
  """
  defmacro prefix(path) do
    path = MaruPath.split path
    quote do
      Resource.push_path(unquote(path))
    end
  end


  @doc """
  Define params block of current endpoint.
  """
  defmacro params(block) do
    quote do
      import Maru.Builder.Namespaces, only: []
      import Kernel, except: [use: 1]
      import Maru.Builder.Params
      @group []
      unquote(block)
      import Maru.Builder.Params, only: []
      import Kernel
      import Maru.Builder.Namespaces
    end
  end


  @doc """
  Define version of current router.
  """
  defmacro version(v) do
    quote do
      Resource.set_version(unquote(v))
    end
  end

  @doc """
  version: "v1", do ... end:
    Version of endpoints within block.

  version: "v2", extend: "v1", at: V1
    Define version and extended router of current router.
  """
  defmacro version(v, [do: block]) do
    quote do
      s = Resource.snapshot
      Resource.set_version(unquote(v))
      unquote(block)
      Resource.restore(s)
    end
  end

  defmacro version(v, opts) do
    quote do
      Resource.set_version(unquote(v))
      @extend {unquote(v), unquote(opts)}
    end
  end

  @doc """
  Import helpers used by current router.
  """
  defmacro helpers([do: block]) do
    block =
      case block do
        nil -> []
        {:__block__, _, list} -> list
        any -> [any]
      end
      |> Maru.Utils.group_by(fn block ->
        case block do
          {method, _, _} when method in [:import, :alias, :require] -> :helpers
          {method, _, _} when method in [:def]                      -> :def
          {method, _, _} when method in [:defp]                     -> :defp
          {method, _, _} when method in [:params]                   -> :params
          {_, _, _}                                                 -> :ignore
        end
      end)
      |> Enum.into([])
    import? = not is_nil(block[:def])
    quote do
      Resource.push_helper(unquote(block[:helpers] |> Macro.escape))
      if unquote(import?) do
        Resource.push_helper(quote do import unquote(__MODULE__) end)
      end
      import Maru.Helpers.Params
      unquote(block[:def])
      unquote(block[:defp])
      unquote(block[:params])
      import Maru.Helpers.Params, only: []
    end
  end

  defmacro helpers({_, _, module}) do
    module = Module.concat(module)
    block = quote do import unquote(module) end |> Macro.escape
    quote do
      Resource.push_helper(unquote(block))
      unquote(module).__shared_params__ |> Enum.each(&(@shared_params &1))
    end
  end

  @doc """
  Define description do current endpoint.
  """
  defmacro desc(desc) do
    quote do
      @desc unquote(desc)
    end
  end

  @doc """
  Mount another router to current router.
  """
  defmacro mount({_, _, mod}) do
    module = Module.concat(mod)
    quote do
      for ep <- unquote(module).__endpoints__ do
        @mounted Maru.Struct.Endpoint.merge(
          @resource, @plugs, ep
        )
      end
    end
  end

  @doc """
  Push a `Plug` struct to current resource scope.
  """
  defmacro plug(plug)

  defmacro plug({:when, _, [plug, guards]}) do
    do_plug(plug, [], guards)
  end

  defmacro plug(plug) do
    do_plug(plug, [], true)
  end

  @doc """
  Push a `Plug` struct with options and guards to current resource scope.
  """
  defmacro plug(plug, opts)

  defmacro plug(plug, {:when, _, [opts, guards]}) do
    do_plug(plug, opts, guards)
  end

  defmacro plug(plug, opts) do
    do_plug(plug, opts, true)
  end

  defp do_plug(plug, opts, guards) do
    quote do
      MaruPlug.push(%MaruPlug{
        name:    nil,
        plug:    unquote(plug),
        options: unquote(opts),
        guards:  unquote(Macro.escape(guards)),
     })
    end
  end

end
