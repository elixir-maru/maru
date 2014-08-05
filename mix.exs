defmodule Lazymaru.Mixfile do
  use Mix.Project

  def project do
    [ app: :lazymaru,
      version: "0.1.2",
      elixir: "~> 0.15.0",
      deps: deps,
      description: "Elixir copy of grape for creating REST-like APIs.",
      source_url: "https://github.com/falood/lazymaru",
      package: package,
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
      { :json, "~> 0.3.0" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/lazymaru"}
     }
  end
end
