require Logger

defmodule Maru do
  @moduledoc """
  This is documentation for maru.

  Maru is a REST-like API micro-framework depends on [plug](http://hexdocs.pm/plug) for [elixir](http://elixir-lang.org) inspired by [grape](https://github.com/ruby-grape/grape).
  """

  @doc """
  Maru version.
  """
  @version Mix.Project.config()[:version]
  def version do
    @version
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

  json_library = Application.get_env(:maru, :json_library, Jason)

  unless Code.ensure_loaded?(json_library) do
    Logger.warn(
      "Json library #{json_library} is not loaded, add your json library to deps and config with `config :maru, :json_library, #{
        json_library
      }`"
    )
  end

  @doc false
  def json_library do
    unquote(json_library)
  end
end
