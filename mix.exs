defmodule Lazymaru.Mixfile do
  use Mix.Project

  def project do
    [ app: :lazymaru,
      version: "0.0.1",
      deps: deps
    ]
  end

  def application do
    [ mod: { Lazymaru, [] },
      applications: [ :cowboy, :plug ]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 0.9", github: "extend/cowboy", ref: "5a25c7f", override: true},
      { :plug,   github: "elixir-lang/plug" },
      { :json,   github: "cblage/elixir-json" },
    ]
  end
end
