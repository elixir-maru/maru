require Logger

defmodule Maru do
  @moduledoc """
  This is documentation for maru.

  Maru is a REST-like API micro-framework depends on [plug](http://hexdocs.pm/plug) for [elixir](http://elixir-lang.org) inspired by [grape](https://github.com/ruby-grape/grape).
  """

  use Application

  @doc """
  Maru version.
  """
  @version Mix.Project.config[:version]
  def version do
    @version
  end

  @default_http_port 4000
  @default_https_port 4040

  @doc false
  def start(_type, _args) do
    Application.ensure_all_started :plug
    for {module, options} <- servers do
      if Keyword.has_key? options, :http do
        opts = options[:http] |> Keyword.merge([port: to_port(options[:http][:port]) || @default_http_port])
        Plug.Adapters.Cowboy.http module, [], opts
        Logger.info "Running #{module} with Cowboy on http://127.0.0.1:#{opts[:port]}"
      end

      if Keyword.has_key? options, :https do
        opts = options[:https] |> Keyword.merge([port: to_port(options[:https][:port]) || @default_https_port])
        Plug.Adapters.Cowboy.https module, [], opts
        Logger.info "Running #{module} with Cowboy on https://127.0.0.1:#{opts[:port]}"
      end
    end
    {:ok, self}
  end

  def servers do
    Enum.filter(Application.get_all_env(:maru), fn {k, _} ->
      match?("Elixir." <> _, to_string(k))
    end)
  end

  defp to_port(nil),                        do: nil
  defp to_port(port) when is_integer(port), do: port
  defp to_port(port) when is_binary(port),  do: port |> String.to_integer
  defp to_port({:system, env_var}),         do: System.get_env(env_var) |> to_port
end
