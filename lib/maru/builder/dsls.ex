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
  Define version of current router.
  """
  defmacro version(v) do
    quote do
      Resource.set_version(unquote(v))
    end
  end

  @doc """
  version: "v1", do ... end:
    Version of routes within block.

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
  Save shared param to module attribute.
  """
  defmacro params(name, [do: block]) do
    quote do
      @shared_params unquote({name, block |> Macro.escape})
    end
  end

  defmacro helpers({_, _, module}) do
    module = Module.concat(module)
    quote do
      unquote(module).__shared_params__ |> Enum.each(&(@shared_params &1))
      import unquote(module)
    end
  end

  defmacro helpers([do: block]) do
    quote do
      import Kernel, only: []
      import Maru.Builder.DSLs, only: [params: 2]
      unquote(block)
      import Maru.Builder.DSLs
      import Maru.Builder.DSLs, except: [params: 2]
      import Kernel
    end
  end

  @doc """
  Push a `Plug` struct to current scope.
  """
  defmacro plug(plug)

  defmacro plug({:when, _, [plug, guards]}) do
    do_plug(nil, plug, [], guards)
  end

  defmacro plug(plug) do
    do_plug(nil, plug, [], true)
  end

  @doc """
  Push a `Plug` struct with options and guards to current scope.
  """
  defmacro plug(plug, opts)

  defmacro plug(plug, {:when, _, [opts, guards]}) do
    do_plug(nil, plug, opts, guards)
  end

  defmacro plug(plug, opts) do
    do_plug(nil, plug, opts, true)
  end

  @doc """
  Push a overridable `Plug` struct to current scope.
  """
  defmacro plug_overridable(name, plug)

  defmacro plug_overridable(name, {:when, _, [plug, guards]}) do
    do_plug(name, plug, [], guards)
  end

  defmacro plug_overridable(name, plug) do
    do_plug(name, plug, [], true)
  end

  @doc """
  Push a overridable `Plug` struct with options and guards to current scope.
  """
  defmacro plug_overridable(name, plug, opts)

  defmacro plug_overridable(name, plug, {:when, _, [opts, guards]}) do
    do_plug(name, plug, opts, guards)
  end

  defmacro plug_overridable(name, plug, opts) do
    do_plug(name, plug, opts, true)
  end

  defp do_plug(name, plug, opts, guards) do
    quote do
      Resource.push_plug(%MaruPlug{
        name:    unquote(name),
        plug:    unquote(plug),
        options: unquote(opts),
        guards:  unquote(Macro.escape(guards)),
     })
    end
  end

end
