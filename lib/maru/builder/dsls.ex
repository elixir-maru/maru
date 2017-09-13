defmodule Maru.Builder.DSLs do
  @moduledoc """
  General DSLs for parsing router.
  """

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

end
