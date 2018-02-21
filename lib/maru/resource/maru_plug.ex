alias Maru.Resource

defmodule Resource.MaruPlug do
  @moduledoc false

  defstruct name: nil,
            plug: nil,
            options: nil,
            guards: true

  @doc "push plug to current plugs stack."
  def push(plug_or_plugs, %Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    new_plugs = merge(plugs, plug_or_plugs)
    Module.put_attribute(module, :plugs, new_plugs)
  end

  @doc "return snapshot and clean current plugs stack."
  def pop(%Macro.Env{module: module}) do
    plugs = Module.get_attribute(module, :plugs)
    Module.get_attribute(module, :plugs, [])
    plugs
  end

  @doc "merge and override plugs."
  def merge(plugs, %__MODULE__{} = pipeline) do
    merge(plugs, [pipeline])
  end

  def merge(plugs, pipelines) do
    Enum.reduce(pipelines, plugs, fn x, acc ->
      do_merge(acc, x, [])
    end)
  end

  defp do_merge([], plug, result) do
    result ++ [plug]
  end

  defp do_merge([%__MODULE__{name: nil} = h | t], plug, result) do
    do_merge(t, plug, result ++ [h])
  end

  defp do_merge([%__MODULE__{name: n} | t], %__MODULE__{name: n} = plug, result) do
    result ++ [plug] ++ t
  end

  defp do_merge([h | t], plug, result) do
    do_merge(t, plug, result ++ [h])
  end
end
