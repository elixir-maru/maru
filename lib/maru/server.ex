defmodule Maru.Server do
  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    quote do
      @otp_options Application.get_env(unquote(otp_app), __MODULE__, [])

      def init(_, opts) do
        {:ok, opts}
      end

      def start_link(opts) do
        opts = Keyword.merge(@otp_options, opts)
        {:ok, opts} = init(:runtime, opts)
        unquote(__MODULE__).start_link(opts)
      end

      def child_spec(opts) do
        opts = Keyword.merge(@otp_options, opts)
        {:ok, opts} = init(:supervisor, opts)
        unquote(__MODULE__).child_spec(opts)
      end

      defoverridable [init: 2]
    end
  end

  @spec start_link(Keyword.t()):: {:ok, pid} | {:error, term}
  @since "0.13.2"
  def start_link(opts) do
    {adapter, scheme, plug, options} = config(opts)
    adapter.child_spec(scheme: scheme, plug: plug, options: options)
    apply(adapter, scheme, [plug, [], options])
  end

  @spec start_link(Keyword.t()):: map()
  @since "0.13.2"
  def child_spec(opts) do
    {adapter, scheme, plug, options} = config(opts)
    adapter.child_spec(scheme: scheme, plug: plug, options: options)
  end

  @default_scheme :http
  @default_ports http: 4000, https: 4040
  @default_bind_addr {127, 0, 0, 1}
  @default_adapter Plug.Adapters.Cowboy2
  defp config(opts) do
    adapter = opts[:adapter] || @default_adapter
    scheme = opts[:scheme] || @default_scheme
    ip = to_ip(opts[:bind_addr]) || opts[:ip] || @default_bind_addr
    port = to_port(opts[:port]) || @default_ports[scheme]
    plug = Keyword.fetch!(opts, :plug)

    options =
      opts
      |> Keyword.drop([:scheme, :plug, :bind_addr, :adapter])
      |> Keyword.merge([ip: ip, port: port])

    {adapter, scheme, plug, options}
  end

  @doc "convert tcp port to integer"
  @since "0.13.2"
  @spec to_port(String.t() | integer()) :: integer()
  def to_port(nil), do: nil
  def to_port(port) when is_integer(port), do: port
  def to_port(port) when is_binary(port), do: port |> String.to_integer()

  @doc "convert string ip address to :inet.ip_address()"
  @since "0.13.2"
  @spec to_ip(String.t()) :: :inet.ip_address()
  def to_ip(nil), do: nil
  def to_ip(ip_addr) do
    {:ok, inet_ip} = ip_addr |> to_charlist |> :inet.parse_address()
    inet_ip
  end
end
