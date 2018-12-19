require Logger

defmodule Maru.Server do
  @moduledoc """
  Defines a server.

  When used, the server expects the `:otp_app` as option. The `:otp_app` should point to an OTP application that has the server configuration. For example, the server:

      defmodule MyServer do
        use Maru.Server, otp_app: :my_api
      end

  Could be configured with:

      config :my_api, MyServer,
        adapter: Plug.Cowboy,
        plug: MyAPI,
        port: 8080,
        scheme: :http,
        bind_addr: "0.0.0.0"

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, module: __MODULE__] do
      @otp_options opts |> Keyword.get(:otp_app) |> Application.get_env(__MODULE__, [])
      @opts opts |> Keyword.delete(:otp_app) |> Keyword.merge(@otp_options)
      @module module

      def init(_, opts) do
        {:ok, opts}
      end

      def start_link(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        {:ok, opts} = init(:runtime, opts)
        @module.start_link(opts)
      end

      def child_spec(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        {:ok, opts} = init(:supervisor, opts)
        @module.child_spec(opts)
      end

      defoverridable init: 2

      def __plug__ do
        @opts[:plug]
      end

      defmacro __using__(options) do
        addition_opts =
          with true <- {:__plug__, 0} in __MODULE__.__info__(:functions),
               true <- __CALLER__.module == __MODULE__.__plug__() do
            [make_plug: true]
          else
            _ -> []
          end

        options = Keyword.merge(addition_opts, options)

        quote do
          use Maru.Builder, unquote(options)
        end
      end
    end
  end

  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, term}
  @since "0.13.2"
  def start_link(opts) do
    {adapter, scheme, plug, options} = config(opts)

    Logger.info(
      "Starting #{plug} with #{adapter} standalone on " <>
        "#{scheme}://#{:inet_parse.ntoa(options[:ip])}:#{options[:port]}"
    )

    apply(adapter, scheme, [plug, [], options])
  end

  @spec start_link(Keyword.t()) :: map()
  @since "0.13.2"
  def child_spec(opts) do
    {adapter, scheme, plug, options} = config(opts)

    Logger.info(
      "Starting #{plug} with #{adapter} under supervisor tree on " <>
        "#{scheme}://#{:inet_parse.ntoa(options[:ip])}:#{options[:port]}"
    )

    adapter.child_spec(scheme: scheme, plug: plug, options: options)
  end

  @default_scheme :http
  @default_ports http: 4000, https: 4040
  @default_bind_addr {127, 0, 0, 1}
  @default_adapter Plug.Cowboy
  defp config(opts) do
    adapter = opts[:adapter] || @default_adapter
    scheme = opts[:scheme] || @default_scheme
    ip = to_ip(opts[:bind_addr]) || opts[:ip] || @default_bind_addr
    port = to_port(opts[:port]) || @default_ports[scheme]
    plug = Keyword.fetch!(opts, :plug)

    options =
      opts
      |> Keyword.drop([:scheme, :plug, :bind_addr, :adapter])
      |> Keyword.merge(ip: ip, port: port)

    {adapter, scheme, plug, options}
  end

  @since "0.13.2"
  @spec to_port(String.t() | integer()) :: integer()
  defp to_port(nil), do: nil
  defp to_port(port) when is_integer(port), do: port
  defp to_port(port) when is_binary(port), do: port |> String.to_integer()

  @since "0.13.2"
  @spec to_ip(String.t()) :: :inet.ip_address()
  defp to_ip(nil), do: nil

  defp to_ip(ip_addr) do
    {:ok, inet_ip} = ip_addr |> to_charlist |> :inet.parse_address()
    inet_ip
  end
end
