defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru,
      name: "Maru",
      version: "0.9.4-dev",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: "REST-like API micro-framework for elixir inspired by grape.",
      source_url: "https://github.com/falood/maru",
      homepage_url: "https://maru.readme.io",
      package: package,
      docs: [
        extras: ["README.md"],
        main: "extra-readme",
      ]
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
      { :poison, "~> 1.5 or ~> 2.0" },
      { :inch_ex, only: :docs },
      { :earmark, "~> 0.1", only: :docs },
      { :ex_doc, "~> 0.10", only: :docs },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/maru"}
     }
  end
end
