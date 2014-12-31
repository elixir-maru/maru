defmodule Maru do
  use Application

  def start(_type, _args) do
    Application.ensure_all_started :plug
    for {module, options} <- Maru.Config.servers do
      Plug.Adapters.Cowboy.http module, [], [port: options[:port]]
    end
    Maru.Supervisor.start_link
  end
end
