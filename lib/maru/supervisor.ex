require Logger

defmodule Maru.Supervisor do
  use Supervisor

  def start_link do
    if Maru.test_mode?() do
      {:ok, self()}
    else
      Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end
  end

  def init([]) do
    for {module, options} <- maru_servers() do
      for protocol <- [:http, :https] do
        if Keyword.has_key?(options, protocol) do
          endpoint_spec(protocol, module, options[protocol])
        end || []
      end
    end
    |> List.flatten()
    |> Supervisor.init(strategy: :one_for_one)
  end

  @default_ports http: 4000, https: 4040
  @default_bind_addr {127, 0, 0, 1}

  defp endpoint_spec(proto, module, opts) do
    bind_addr = to_ip(opts[:bind_addr]) || opts[:ip] || @default_bind_addr

    normalized_opts =
      opts
      |> Keyword.merge(port: to_port(opts[:port]) || @default_ports[proto])
      |> Keyword.merge(ip: bind_addr)
      |> Keyword.delete(:bind_addr)

    Logger.info(
      "Starting #{module} with Cowboy on " <>
        "#{proto}://#{:inet_parse.ntoa(bind_addr)}:#{opts[:port]}"
    )

    args = [scheme: proto, plug: module, options: normalized_opts]

    if Code.ensure_loaded?(:cowboy_http2) do
      Plug.Adapters.Cowboy2.child_spec(args)
    else
      Plug.Adapters.Cowboy.child_spec(args)
    end
  end

  defp to_port(nil), do: nil
  defp to_port(port) when is_integer(port), do: port
  defp to_port(port) when is_binary(port), do: port |> String.to_integer()

  defp to_ip(nil), do: nil

  defp to_ip(ip_addr) do
    {:ok, inet_ip} = :inet_parse.ipv4_address(String.to_charlist(ip_addr))
    inet_ip
  end

  defp maru_servers do
    if Code.ensure_loaded?(Confex) do
      Enum.map(Maru.servers(), fn {k, v} ->
        {k, apply(Confex.Resolver, :resolve!, [v])}
      end)
    else
      Maru.servers()
    end
  end
end
