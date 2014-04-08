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
      applications: [ :cowboy ]
    ]
  end

  defp deps do
    [{ :cowboy, github: "extend/cowboy" }]
  end
end
