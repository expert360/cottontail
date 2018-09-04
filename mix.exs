defmodule Cottontail.MixProject do
  use Mix.Project

  def project do
    [
      app: :cottontail,
      version: "0.1.4",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Cottontail.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:amqp, "~> 1.0"},
      {:poolboy, "~> 1.5"},
      {:credo, ">= 0.0.0", only: [:dev, :test]},
      {:excoveralls, ">= 0.0.0", only: :test},
      {:ex_doc, "~> 0.18.0", only: :dev}
    ]
  end

  defp package do
    [
      files: [
        "LICENSE.md",
        "mix.exs",
        "mix.lock",
        "README.md",
        "lib",
      ],
      links: %{"GitHub" => "https://github.com/expert360/cottontail"},
      licenses: ["Apache 2.0"],
      maintainers: ["Declan Kennedy"],
    ]
  end

  defp description do
    "A simple helper library for using AMQP with Elixir"
  end
end
