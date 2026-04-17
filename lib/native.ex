defmodule HarfbuzzEx.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :harfbuzz_ex,
    crate: "harfbuzz_ex",
    base_url: "https://github.com/jkwchui/harfbuzz_ex/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
    version: version,
    targets: [
        "aarch64-apple-darwin",
        "x86_64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc",
        "x86_64-pc-windows-gnu"
      ],
    nif_versions: ["2.15", "2.16"]

  def shaper_new(_path), do: :erlang.nif_error(:nif_not_loaded)
  def shaper_shape(_resource, _text), do: :erlang.nif_error(:nif_not_loaded)
  def shaper_destroy(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
