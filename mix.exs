defmodule Lazymaru.Mixfile do
  use Mix.Project

  def project do
    [ app: :lazymaru,
      version: "0.1.0",
      elixir: "~> 0.15.0",
      deps: deps
    ]
  end

  def application do
    [ mod: { Lazymaru, [] },
      applications: [ :cowboy, :plug ]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :plug, "~> 0.5.3" },
      { :json, github: "cblage/elixir-json" },
    ]
  end
end
