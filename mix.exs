defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru,
      name: "Maru",
      version: "0.12.5",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "REST-like API micro-framework for elixir inspired by grape.",
      source_url: "https://github.com/elixir-maru/maru",
      homepage_url: "https://maru.readme.io",
      package: package(),
      docs: [
        extras: ["README.md"],
        main: "readme",
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
    ]
  end

  def application do
    [ mod: { Maru, [] },
      applications: [ :ranch, :cowboy, :plug, :poison ]
    ]
  end

  defp deps do
    [ { :cowboy,  "~> 1.1" },
      { :plug,    "~> 1.4" },
      { :poison,  "~> 3.0" },
      { :inch_ex, "~> 0.5",  only: :docs },
      { :earmark, "~> 1.2",  only: :docs },
      { :ex_doc,  "~> 0.16", only: :docs },
      { :excoveralls, "~> 0.7.4", only: [:dev, :test] },
    ]
  end

  defp package do
    %{ maintainers: ["Xiangrong Hao"],
       licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/elixir-maru/maru"}
     }
  end
end
