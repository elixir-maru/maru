defmodule Lazymaru do
  use Application.Behaviour

  def start(_type, _args) do
    Lazymaru.Supervisor.start_link
  end
end
