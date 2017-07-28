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

  @doc false
  def start(_type, _args) do
    Maru.Supervisor.start_link
  end

  @doc false
  def servers do
    Enum.filter(Application.get_all_env(:maru), fn {module, _} ->
      cond do
        not match?("Elixir." <> _, to_string(module)) -> false
        not Code.ensure_loaded?(module) ->
          Logger.info "Maru router `#{module}` defined in config but not loaded, ignore..."
          false
        not {:call, 2} in module.__info__(:functions) ->
          Logger.info "your module  `#{module}` defined in config is not a maru router, ignore..."
          false
        true -> true
      end
    end)
  end

  @doc false
  def test_mode? do
    case Application.get_env(:maru, :test) do
      true  -> true
      false -> false
      nil   -> Mix.env == :test
    end
  end

end
