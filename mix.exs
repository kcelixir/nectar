defmodule Nectar.MixProject do
  use Mix.Project

  def project do
    [
      app: :nectar,
      version: "0.1.0",
      elixir: "~> 1.6",
      # build_embedded
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Nectar",
      source_url: "https://github.com/kcelixir/nectar",
      preferred_cli_env: [espec: :test],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nectar, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:espec, "~> 1.5", only: :test},
      {:httpoison, "~> 1.0", only: [:dev, :test]},
    ]
  end

  defp description do
    "A simple HTTP server implemented in Elixir. Intended to be a replacement for cowboy."
  end

  defp package do
    [
      # name
      # organization: "kcelixir",
      files: [ "lib", "mix.exs", "README*", "LICENSE*" ],
      maintainers: [
        "Craig S. Cottingham",
        "Jeffery Utter",
      ],
      licenses: [ "Apache 2.0" ],
      links: %{
        "Github" => "https://github.com/kcelixir/nectar",
      }
    ]
  end
end
