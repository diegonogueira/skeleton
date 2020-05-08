defmodule Skeleton.MixProject do
  use Mix.Project

  @version "1.0.0"
  @url "https://github.com/diegonogueira/skeleton"
  @maintainers [
    "Diego Nogueira",
    "Jhonathas Matos"
  ]

  def project do
    [
      name: "Skeleton",
      app: :skeleton,
      version: @version,
      elixir: "~> 1.10.3",
      package: package(),
      source_url: @url,
      maintainers: @maintainers,
      description: "Elixir structure",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:plug_cowboy, "~> 2.2"}
    ]
  end

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(lib) ++ ~w(CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end
end
