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
      use Maru.Builder.Plugins.Pipeline
      use Maru.Builder.Plugins.Exception
      use Maru.Builder.Plugins.PlugRouter, unquote(opts)
      use Maru.Builder.Plugins.Description
      use Maru.Builder.Plugins.Route
      use Maru.Builder.Plugins.Endpoint

      use Maru.Helpers.Response

      require Maru.Struct.Parameter
      require Maru.Struct.Resource
      require Maru.Struct.Plug

      import Maru.Builder.Namespaces
      import Maru.Builder.Methods
      import Maru.Builder.DSLs, except: [params: 2]

      Module.register_attribute __MODULE__, :shared_params, accumulate: true

      @extend     nil
      @resource   %Maru.Struct.Resource{}
      @parameters []
      @func_id    0

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{}=env) do
    Maru.Builder.Plugins.Route.callback_before_compile(env)
    Maru.Builder.Plugins.Exception.callback_before_compile(env)
    Maru.Builder.Plugins.PlugRouter.callback_before_compile(env)
    Maru.Builder.Plugins.Endpoint.callback_before_compile(env)
  end
end
