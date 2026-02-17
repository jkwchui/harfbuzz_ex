defmodule HarfbuzzEx.Shaper do
  @moduledoc """
  Access point for font-shaping.

  If I/O and memory are not concerns (the font file is small, or the task infrequent), use `get/3` to access data from the shaped glyphs directly.

  If the font file-size is large and shaping is done frequently, you should
  explicitly use the GenServer `start_link/1` to load the font into memory. Shaping with `shape/2` is then CPU bound.  Use `stop/1` to release the memory.
  """

  use GenServer

  alias HarfbuzzEx.Native

  @doc """
  Input a string, shape with the font, and return a list of shaped glyphs.

  Use `:all` for a list of `%HarfbuzzEx.Glyph{}` structs, or one of `:name`, `:x_advance`, `:y_advance`, `:x_offset`, `:y_offset` for a list of string (`:name`) or integers.
  """
  def get(string, font_path, data \\ :name) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset, :all] do
    {:ok, shaper} = HarfbuzzEx.Shaper.start_link(font_path)
    {:ok, results} = HarfbuzzEx.Shaper.shape(shaper, string)
    HarfbuzzEx.Shaper.stop(shaper)

    case data do
      :all -> results
      _    -> results |> Enum.map(&Map.get(&1, data))
    end
  end

  # --- Client API ---

  @doc """
  Starts a new Shaper process for the given font.
  Returns `{:ok, pid}` on success.
  """
  def start_link(font_path, opts \\ []) do
    GenServer.start_link(__MODULE__, font_path, opts)
  end

  @doc """
  Shapes text using the given Shaper process.
  """
  def shape(pid, text) do
    GenServer.call(pid, {:shape, text})
  end

  @doc """
  Stops the Shaper process.
  This drops the reference to the Rust resource, allowing the BEAM
  to garbage collect the memory (font data + parsed tables).
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  # --- Server Callbacks ---

  @impl true
  def init(font_path) do
    # Load the heavy resource once during process initialization
    case Native.shaper_new(font_path) do
      {:error, reason} -> {:stop, reason}
      resource -> {:ok, resource}
    end
  end

  @impl true
  def handle_call({:shape, text}, _from, resource) do
    # The resource is kept in the loop state
    result = Native.shaper_shape(resource, text)
    {:reply, {:ok, result}, resource}
  end
end
