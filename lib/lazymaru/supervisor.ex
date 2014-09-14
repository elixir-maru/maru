defmodule Lazymaru.Supervisor do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  # Application.ensure_all_started :plug
  # for {module, options} <- Lazymaru.Config.plugs do
  #   Plug.Adapters.Cowboy.http module, [], [port: options[:port]]
  # end
  # Lazymaru.Supervisor.start_link


  def init([]) do
    # for {module, options} <- Lazymaru.Config.plugs do
    #   Plug.Adapters.Cowboy.child_spec :http, module, [], [port: options[:port]]
    # end |> IO.inspect |> supervise(strategy: :one_for_one)

    children = [ ]
    supervise(children, strategy: :one_for_one)
  end
end
