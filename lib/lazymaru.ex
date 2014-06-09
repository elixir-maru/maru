defmodule Lazymaru do
  use Application

  def start(_type, _args) do
    Lazymaru.Supervisor.start_link
  end
end
