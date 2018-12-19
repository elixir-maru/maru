defmodule Maru.Mixfile do
  use Mix.Project

  def project do
    [
      app: :maru,
      name: "Maru",
      version: "0.14.0-pre.1",
      elixir: "~> 1.4",
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
    [applications: [:ranch, :cowboy, :plug]]
  end

  defp deps do
    [
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 1.0 or ~> 2.0", optional: true},
      {:jason, "~> 1.0 or ~> 1.1", optional: true},
      {:inch_ex, "~> 1.0", only: :docs},
      {:ex_doc, "~> 0.19", only: :docs}
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
