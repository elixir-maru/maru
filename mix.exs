defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru,
      version: "0.8.1-dev",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: "REST-like API micro-framework for elixir inspired by grape.",
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
    [ { :cowboy, "~> 1.0" },
      { :plug,   "~> 1.0" },
      { :poison, "~> 1.5" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/maru"}
     }
  end
end
