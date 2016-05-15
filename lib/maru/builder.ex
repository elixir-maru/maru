defmodule Maru.Builder do
  @moduledoc """
  Generate functions.

  For all modules:
      A function named `__routes__/0` will be generated for returning routes.
      Mounted and extended routes are included.

  For all environments except `:prod`:
      Two functions `__version__/0` and `call_test/2` will be generated for testing.

  For plug modules:
      You can define a plug module by `use Maru.Router, make_plug: true` or
      `config :maru, MyPlugModule` within config.exs.
      Two functions `init/1` and `call/2` will be generated for making this module
      a `Plug`. And a private function `endpoint/2` which is called by this `Plug`
      will be generated.
  """

  @doc false
  defmacro __using__(opts) do
    make_plug = opts |> Keyword.get(:make_plug, false)
    quote do
      use Maru.Helpers.Response

      require Maru.Struct.Parameter
      require Maru.Struct.Resource
      require Maru.Struct.Plug

      import Maru.Builder.Namespaces
      import Maru.Builder.Methods
      import Maru.Builder.Exceptions
      import Maru.Builder.DSLs

      Module.register_attribute __MODULE__, :plugs_before,  accumulate: true
      Module.register_attribute __MODULE__, :routes,        accumulate: true
      Module.register_attribute __MODULE__, :endpoints,     accumulate: true
      Module.register_attribute __MODULE__, :mounted,       accumulate: true
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      Module.register_attribute __MODULE__, :exceptions,    accumulate: true


      @extend        nil
      @resource      %Maru.Struct.Resource{}
      @desc          nil
      @parameters    []
      @plugs         []
      @func_id       0

      @make_plug unquote(make_plug) or not is_nil(Application.get_env(:maru, __MODULE__))
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    [ Maru.Builder.Plugs.Router.compile(env),
      unless Mix.env == :prod do
        Maru.Builder.Plugs.Test.compile(env)
      end,
      if Module.get_attribute(module, :make_plug) do
        Maru.Builder.Plugs.Server.compile(env)
      end,
    ]
  end

end
