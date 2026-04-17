# HarfbuzzEx

`HarfbuzzEx` does OpenType font shaping by wrapping Rust's `rustybuzz` crate.  The package provides precompiled binaries so it can be used without the Rust toolchain installed.

## Installation

The package can be installed
by adding `harfbuzz_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:harfbuzz_ex, "~> 1.1"}
  ]
end
```

## Usage

For one-off font-shaping use `HarfbuzzEx.get/2`.  The first argument is the path to the OpenType font, and the second argument is the text to be shaped.  This returns a list of maps, where each map holds a shaped glyph.

Often only one aspect of the shaped text is needed, for example, the glyphnames.  `HarfbuzzEx.get/3` accepts an additional parameter such as `:name` and returns a list containing only that aspect of the shaped glyph.

Fonts involving complex shaping or large file size, such as Arabic or CJK scripts, benefit from being loaded into memory instead of invoking I/O and creating/destroying a new Rust instance on every function call.  In these cases, use `HarfbuzzEx.new/1` with the font file path to create a GenServer.  The GenServer `pid` can then be used in `HarfbuzzEx.shape/2` and `HarfbuzzEx.shape/3` in similar fashion as `get/2` and `get/3`.  The GenServer can be destroyed to release memory using `HarfbuzzEx.stop/1`.
