defmodule HarfbuzzEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :harfbuzz_ex,
      version: "1.0.5",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Elixir binding for Harfbuzz using Rustybuzz as NIF, with RustlerPrecompiled",
      source_url: "https://github.com/jkwchui/harfbuzz_ex"
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native/harfbuzz_ex/src",
        "native/harfbuzz_ex/Cargo.toml",
        "native/harfbuzz_ex/Cargo.lock",
        "mix.exs",
        "README.md",
        "LICENSE",
        "checksum-Elixir.HarfbuzzEx.exs"
      ],
      maintainers: ["Jon Chui"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jkwchui/harfbuzz_ex"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler, "~> 0.30", runtime: false},
      {:rustler_precompiled, "~> 0.7"}
    ]
  end
end
