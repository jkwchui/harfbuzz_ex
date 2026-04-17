defmodule HarfbuzzEx do
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
  otp_app: :harfbuzz_ex,
  crate: "harfbuzz_ex",
  base_url: "https://github.com/jkwchui/harfbuzz_ex/releases/download/v#{version}",
  force_build: Mix.env() == :dev,
  # force_build: System.get_env("BUILD_NATIVE") == "true",
  version: version,
  targets: [
      "aarch64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "x86_64-pc-windows-msvc",
      "x86_64-pc-windows-gnu"
    ],
  nif_versions: ["2.15", "2.16"]

end
