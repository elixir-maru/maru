require Logger

defmodule Maru do
  @moduledoc """
  This is documentation for maru.

  Maru is a REST-like API micro-framework depends on [plug](http://hexdocs.pm/plug) for [elixir](http://elixir-lang.org) inspired by [grape](https://github.com/ruby-grape/grape).
  """

  use Application
  use Supervisor

  @doc """
  Maru version.
  """
  @version Mix.Project.config[:version]
  def version do
    @version
  end

  @default_ports http: 4000, https: 4040
  @default_bind_addr {127, 0, 0, 1}

  @doc false
  def start(_type, _args) do
    Application.ensure_all_started :plug

    children =
      for {module, options} <- servers() do
        for protocol <- [:http, :https] do
          if Keyword.has_key? options, protocol do
            endpoint_spec(protocol, module, options[protocol])
          end || []
        end
      end

    opts = [strategy: :one_for_one, name: Maru.Supervisor]
    Supervisor.start_link(List.flatten(children), opts)
  end

  def servers do
    servers =
      Enum.filter(Application.get_all_env(:maru), fn {k, _} ->
        match?("Elixir." <> _, to_string(k))
      end)
    # If Confex is available, replace all system variables
    case Code.ensure_loaded?(Confex) do
      true ->
        Enum.map(servers, fn {k, v} ->
          {k, Confex.process_env(v)}
        end)
      false ->
        servers
    end
  end

  defp endpoint_spec(proto, module, opts) do
    bind_addr = to_ip(opts[:bind_addr]) || opts[:ip] || @default_bind_addr

    normalized_opts =
      opts
      |> Keyword.merge([port: to_port(opts[:port]) || @default_ports[proto]])
      |> Keyword.merge([ip: bind_addr])
      |> Keyword.delete(:bind_addr)
    Logger.info "Starting #{module} with Cowboy on " <>
                "#{proto}://#{:inet_parse.ntoa(bind_addr)}:#{opts[:port]}"
    Plug.Adapters.Cowboy.child_spec(proto, module, [], normalized_opts)
  end

  defp to_port(nil),                        do: nil
  defp to_port(port) when is_integer(port), do: port
  defp to_port(port) when is_binary(port),  do: port |> String.to_integer

  defp to_ip(nil), do: nil
  defp to_ip(ip_addr) do
    {:ok, inet_ip} = :inet_parse.ipv4_address(String.to_charlist(ip_addr))
    inet_ip
  end
end
