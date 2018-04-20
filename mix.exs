defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [
      app: :maru,
      name: "Maru",
      version: "0.13.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "REST-like API micro-framework for elixir inspired by grape.",
      source_url: "https://github.com/elixir-maru/maru",
      homepage_url: "https://maru.readme.io",
      package: package(),
      docs: [
        extras: ["README.md"],
        main: "readme"
      ]
    ]
  end

  def application do
    [mod: {Maru, []}, applications: [:ranch, :cowboy, :plug]]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.1 or ~> 1.1 or ~> 2.1", optional: true},
      {:plug, "~> 1.5"},
      {:jason, "~> 1.0", optional: true},
      {:inch_ex, "~> 0.5", only: :docs},
      {:earmark, "~> 1.2", only: :docs},
      {:ex_doc, "~> 0.16", only: :docs}
    ]
  end

  defp package do
    %{
      maintainers: ["Xiangrong Hao"],
      licenses: ["BSD 3-Clause"],
      links: %{"Github" => "https://github.com/elixir-maru/maru"}
    }
  end
end
