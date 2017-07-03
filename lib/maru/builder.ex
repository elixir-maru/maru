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
    make_plug = opts |> Keyword.get(:make_plug, false)
    warning_keys = Keyword.drop(opts, [:make_plug]) |> Keyword.keys

    quote do
      Maru.Utils.warning_unknown_opts(__MODULE__, unquote(warning_keys))

      use Maru.Helpers.Response

      require Maru.Struct.Parameter
      require Maru.Struct.Resource
      require Maru.Struct.Plug

      import Maru.Builder.Namespaces
      import Maru.Builder.Methods
      import Maru.Builder.Exceptions
      import Maru.Builder.DSLs, except: [params: 2]

      Module.register_attribute __MODULE__, :plugs_before,  accumulate: true
      Module.register_attribute __MODULE__, :routes,        accumulate: true
      Module.register_attribute __MODULE__, :endpoints,     accumulate: true
      Module.register_attribute __MODULE__, :mounted,       accumulate: true
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      Module.register_attribute __MODULE__, :exceptions,    accumulate: true


      @extend     nil
      @resource   %Maru.Struct.Resource{}
      @desc       nil
      @parameters []
      @plugs      []
      @func_id    0

      @make_plug unquote(make_plug) or not is_nil(Application.get_env(:maru, __MODULE__))
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    current_routes = Module.get_attribute(module, :routes)  |> Enum.reverse
    mounted_routes = Module.get_attribute(module, :mounted) |> Enum.reverse
    extend_opts    = Module.get_attribute(module, :extend)
    extended       = Maru.Builder.Extend.take_extended(
      current_routes ++ mounted_routes, extend_opts
    )
    all_routes     = current_routes ++ mounted_routes ++ extended

    exceptions =
      Module.get_attribute(module, :exceptions)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Exceptions.make_rescue_block/1)
      |> List.flatten

    endpoints_block =
      Module.get_attribute(module, :endpoints)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Endpoint.dispatch/1)

    [ unless Enum.empty?(exceptions) do
        quote do
          def __error_handler__(func) do
            fn ->
              try do
                func.()
              rescue
                unquote(exceptions)
              end
            end
          end
        end
      end,

      endpoints_block,

      quote do
        def __routes__, do: unquote(Macro.escape(all_routes))
      end,

      if Module.get_attribute(module, :make_plug) do
        Maru.Builder.PlugRouter.__before_compile__(env, all_routes)
      end,
    ]
  end

  @doc false
  def make_routes_block(routes, env, version_adapter) do
    Enum.map(routes, fn route ->
      Maru.Builder.Route.dispatch(route, env, version_adapter)
    end)
  end

  @doc false
  def make_method_not_allowed_block(routes, version_adapter) do
    Enum.group_by(routes, fn route -> {route.version, route.path, route.mount_link} end)
    |> Enum.map(fn {{version, path, mount_link}, routes} ->
      unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
        Maru.Builder.Route.dispatch_405(version, path, mount_link, version_adapter)
      end
    end)
  end


end
