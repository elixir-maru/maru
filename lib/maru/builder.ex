defmodule Maru.Builder do
  @moduledoc """
  Generate functions.

  For all modules:
      Two functions will be generated.
      `__routes__/0` for returning routes.
      `endpoint/2` for execute endpoint block.

  For plug modules:
      You can define a plug module by `use Maru.Router, make_plug: true` or
      `config :maru, MyPlugModule` within config.exs.
      Two functions `init/1` and `call/2` will be generated for making this module
      a `Plug`. The function `endpoint/2` will be called by this `Plug`.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      use Maru.Resource

      use Maru.Builder.Pipeline
      use Maru.Builder.Exception
      use Maru.Builder.PlugRouter, unquote(opts)
      use Maru.Builder.Description
      use Maru.Builder.Parameter

      use Maru.Response

      import Maru.Helper.DSLs

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{} = env) do
    Maru.Resource.before_compile_router(env)

    Maru.Builder.Exception.before_compile_router(env)
    Maru.Builder.PlugRouter.before_compile_router(env)
  end
end
