defmodule Lazymaru.Mixfile do
  use Mix.Project

  def project do
    [ app: :lazymaru,
      version: "0.2.1",
      elixir: "~> 1.0.0",
      deps: deps,
      description: "Elixir copy of grape for creating REST-like APIs.",
      source_url: "https://github.com/falood/lazymaru",
      package: package,
    ]
  end

  def application do
    [ mod: { Lazymaru, [] } ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :plug,   "~> 0.8.0" },
      { :poison, "~> 1.2.0" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/lazymaru"}
     }
  end
end
