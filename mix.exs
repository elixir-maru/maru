defmodule Lazymaru.Mixfile do
  use Mix.Project

  def project do
    [ app: :lazymaru,
      version: "0.0.2",
      elixir: "~> 0.13.1",
      deps: deps
    ]
  end

  def application do
    [ mod: { Lazymaru, [] },
      applications: [ :cowboy, :plug ]
    ]
  end

  defp deps do
    [ { :cowboy, github: "extend/cowboy" },
      { :plug,   github: "elixir-lang/plug" },
      { :json,   github: "cblage/elixir-json" },
    ]
  end
end
