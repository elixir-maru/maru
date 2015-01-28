defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru,
      version: "0.2.7",
      elixir: "~> 1.0.0",
      deps: deps,
      description: "Elixir copy of grape for creating REST-like APIs.",
      source_url: "https://github.com/falood/maru",
      package: package,
    ]
  end

  def application do
    [ mod: { Maru, [] },
      applications: [ :plug, :cowboy, :poison ]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :plug,   "~> 0.10.0" },
      { :poison, "~> 1.3.1" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/maru"}
     }
  end
end
