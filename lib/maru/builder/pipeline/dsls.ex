defmodule Maru.Builder.Pipeline.DSLs do
  alias Maru.Resource.MaruPlug

  @doc """
  Define pipeline block of current endpoint.
  """
  defmacro pipeline(block) do
    quote do
      import Kernel, only: []
      import Maru.Resource.DSLs, only: []

      import Maru.Builder.Pipeline.DSLs,
        only: [
          plug: 1,
          plug: 2,
          plug_overridable: 2,
          plug_overridable: 3
        ]

      unquote(block)
      import Maru.Builder.Pipeline.DSLs, only: [pipeline: 1]
      import Maru.Resource.DSLs
      import Kernel
    end
  end

  @doc """
  Push a `Plug` struct to current resource scope.
  """
  defmacro plug(plug)

  defmacro plug({:when, _, [plug, guards]}) do
    do_plug(nil, plug, [], guards)
  end

  defmacro plug(plug) do
    do_plug(nil, plug, [], true)
  end

  @doc """
  Push a `Plug` struct with options and guards to current resource scope.
  """
  defmacro plug(plug, opts)

  defmacro plug(plug, {:when, _, [opts, guards]}) do
    do_plug(nil, plug, opts, guards)
  end

  defmacro plug(plug, opts) do
    do_plug(nil, plug, opts, true)
  end

  @doc """
  Push a overridable `Plug` struct to current resource scope.
  """
  defmacro plug_overridable(name, plug)

  defmacro plug_overridable(name, {:when, _, [plug, guards]}) do
    do_plug(name, plug, [], guards)
  end

  defmacro plug_overridable(name, plug) do
    do_plug(name, plug, [], true)
  end

  @doc """
  Push a overridable `Plug` struct with options and guards to current resource scope.
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
      MaruPlug.push(
        %MaruPlug{
          name: unquote(name),
          plug: unquote(plug),
          options: unquote(opts),
          guards: unquote(Macro.escape(guards))
        },
        __ENV__
      )
    end
  end
end
