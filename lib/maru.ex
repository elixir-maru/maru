require Logger

defmodule Maru do
  use Application

  def start(_type, _args) do
    Application.ensure_all_started :plug
    for {module, options} <- Maru.Config.servers do
      if Keyword.has_key? options, :port do
        IO.puts "warning: :port in maru config is deprecated, please use http[:port] instead\n"
        Plug.Adapters.Cowboy.http module, [], options
        Logger.info "Running #{module} with Cowboy on http://127.0.0.1:#{options[:port]}"
      else
        if Keyword.has_key? options, :http do
          Plug.Adapters.Cowboy.http module, [], options[:http]
          Logger.info "Running #{module} with Cowboy on http://127.0.0.1:#{options[:http][:port]}"
        end
        if Keyword.has_key? options, :https do
          Plug.Adapters.Cowboy.https module, [], options[:https]
          Logger.info "Running #{module} with Cowboy on https://127.0.0.1:#{options[:https][:port]}"
        end
      end
    end
    Maru.Supervisor.start_link
  end
end
