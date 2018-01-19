defmodule Analytics.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :analytics,
      description: "Universal analytics client, currently only supports Mixpanel",
      package: package(),
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]],
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.10"},
      {:poison, "~> 3.1"},
      {:ex_doc, ">= 0.16.0", only: [:dev, :test]},
      {:excoveralls, ">= 0.7.0", only: [:dev, :test]},
      {:dogma, "> 0.1.0", only: [:dev, :test]},
      {:credo, ">= 0.8.0", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:inch_ex, ">= 0.0.0", only: :test}
    ]
  end

  defp package do
    [
      contributors: ["Nebo #15"],
      maintainers: ["Nebo #15"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/contractbook/analytics"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end
end
