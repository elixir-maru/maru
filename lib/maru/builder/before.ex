defmodule Maru.Builder.Before do
  @moduledoc """
  DSLs for defining top-level plugs.
  """

  @doc """
  Define a top-level `Plug`.
  """
  defmacro plug(plug)

  defmacro plug({:when, _, [plug, guards]}) do
    do_plug(plug, [], guards)
  end

  defmacro plug(plug) do
    do_plug(plug, [], true)
  end

  @doc """
  Define a top-level `Plug` struct with options and guards.
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
      @plugs_before {
        unquote(plug),
        unquote(opts),
        unquote(Macro.escape(guards)),
     }
    end
  end


  @doc """
  Warning when use plug_overridable within `before` block.
  """
  defmacro plug_overridable(_, _, _ \\ nil) do
    quote do
      Maru.Utils.warn "#{inspect __MODULE__}: plug_overridable not works within `before` block, Ignore.\n"
    end
  end

end
