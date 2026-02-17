defmodule HarfbuzzEx.Native do
  use Rustler, otp_app: :harfbuzz_ex, crate: "harfbuzz_ex"

  def shaper_new(_path), do: :erlang.nif_error(:nif_not_loaded)
  def shaper_shape(_resource, _text), do: :erlang.nif_error(:nif_not_loaded)
  def shaper_destroy(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
