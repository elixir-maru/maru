defmodule Maru.Builder do
  @moduledoc """
  Generate functions.

  For all modules:
      Two functions will be generated.
      `__routes__/0` for returning routes.
      `endpoint/2` for execute endpoint block.

  For test environments:
      A function named `__version__/0` generated.

  For plug modules:
      You can define a plug module by `use Maru.Router, make_plug: true` or
      `config :maru, MyPlugModule` within config.exs.
      Two functions `init/1` and `call/2` will be generated for making this module
      a `Plug`. The function `endpoint/2` will be called by this `Plug`.
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
      import Maru.Builder.DSLs, except: [params: 2]

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
      @test Application.get_env(:maru, :test) || (Mix.env == :test)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    config = (Application.get_env(:maru, module) || [])[:versioning] || []
    current_routes = Module.get_attribute(module, :routes)  |> Enum.reverse
    mounted_routes = Module.get_attribute(module, :mounted) |> Enum.reverse
    extend_opts    = Module.get_attribute(module, :extend)
    extended       = Maru.Builder.Extend.take_extended(
      current_routes ++ mounted_routes, extend_opts
    )
    all_routes     = current_routes ++ mounted_routes ++ extended

    {routes, adapter, plugs_before, make_plug?, test?} =
      if Module.get_attribute(module, :test) do
        { current_routes,
          Maru.Builder.Versioning.Test,
          [],
          true,
          true,
        }
      else
        { all_routes,
          Maru.Builder.Versioning.get_adapter(config[:using]),
          Module.get_attribute(module, :plugs_before) |> Enum.reverse,
          Module.get_attribute(module, :make_plug),
          false,
        }
      end

    pipeline = [
      [{Maru.Plugs.SaveConn, [], true}],
      plugs_before,
      adapter.get_version_plug(config),
      [ {:route, [], true},
        {Maru.Plugs.NotFound, [], true},
      ],
    ] |> Enum.concat |> Enum.reverse

    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    exceptions =
      Module.get_attribute(module, :exceptions)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Exceptions.make_rescue_block/1)
      |> List.flatten

    routes_block =
      Enum.map(routes, fn route ->
        Maru.Builder.Route.dispatch(route, env, adapter)
      end)

    method_not_allow_block =
      Enum.group_by(routes, fn route -> {route.version, route.path, route.mount_link} end)
      |> Enum.map(fn {{version, path, mount_link}, routes} ->
        unless Enum.any?(routes, fn i -> i.method == {:_, [], nil} end) do
          Maru.Builder.Route.dispatch_405(version, path, mount_link, adapter)
        end
      end)

    endpoints_block =
      Module.get_attribute(module, :endpoints)
      |> Enum.reverse
      |> Enum.map(&Maru.Builder.Endpoint.dispatch/1)

    [ if make_plug? do
        quote do
          unquote(routes_block)
          unquote(method_not_allow_block)
          defp route(conn, _), do: conn

          def init(_), do: []
          def call(unquote(conn), _) do
            unquote(body)
          end
        end
      end,

      unless Enum.empty?(exceptions) do
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

      if test? do
        quote do
          def __version__, do: Maru.Struct.Resource.get_version
        end
      end,

      quote do
        def __routes__, do: unquote(Macro.escape(all_routes))
        unquote(endpoints_block)
      end,
    ]
  end

end
