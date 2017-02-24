defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru,
      name: "Maru",
      version: "0.11.4-dev",
      elixir: "~> 1.2.3 or ~> 1.3 or ~> 1.4",
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
      ]
    ]
  end

  def application do
    [ mod: { Maru, [] },
      applications: [ :plug, :cowboy, :poison ]
    ]
  end

  defp deps do
    [ { :cowboy,  "~> 1.0" },
      { :plug,    "~> 1.0" },
      { :poison,  "~> 1.5 or ~> 2.0 or ~> 3.0" },
      { :confex,  "~> 1.4",  optional: true },
      { :inch_ex, "~> 0.5",  only: :docs },
      { :earmark, "~> 1.0",  only: :docs },
      { :ex_doc,  "~> 0.14", only: :docs },
    ]
  end

  defp package do
    %{ maintainers: ["Xiangrong Hao"],
       licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/elixir-maru/maru"}
     }
  end
end
