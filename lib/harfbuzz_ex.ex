defmodule HarfbuzzEx do
  version = Mix.Project.config()[:version]
  # use Rustler,
  #   otp_app: :harfbuzz_ex,
  #   crate: :harfbuzzex

  use RustlerPrecompiled,
  otp_app: :harfbuzz_ex,
  crate: "harfbuzzex",
  base_url: "https://github.com/jkwchui/harfbuzz_ex/releases/download/v#{version}",
  force_build: System.get_env("BUILD_NATIVE") == "true",
  version: version

  defmodule Glyph do
    defstruct [:name, :x_advance, :y_advance, :x_offset, :y_offset]
  end

  def shape(_text, _font_path), do: :erlang.nif_error(:nif_not_loaded)
end
