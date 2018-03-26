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
  @version Mix.Project.config()[:version]
  def version do
    @version
  end

  @doc false
  def start(_type, _args) do
    Maru.Supervisor.start_link()
  end

  @doc false
  def servers do
    Enum.filter(Application.get_all_env(:maru), fn {module, _} ->
      with true <- match?("Elixir." <> _, to_string(module)),
           true <- Code.ensure_loaded?(module) || :module_not_loaded,
           true <- function_exported?(module, :call, 2) || :function_not_exported do
        true
      else
        :module_not_loaded ->
          Logger.info("Maru router `#{module}` defined in config but not loaded, ignore...")
          false

        :function_not_exported ->
          Logger.info(
            "your module  `#{module}` defined in config is not a maru router, ignore..."
          )

          false

        _ ->
          false
      end
    end)
  end

  @doc false
  @mix_env Mix.env()
  def test_mode? do
    case Application.get_env(:maru, :test) do
      true -> true
      false -> false
      nil -> @mix_env == :test
    end
  end

  @doc false
  def json_library do
    Application.get_env(:maru, :json_library, Jason)
  end
end
