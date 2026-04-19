defmodule HarfbuzzEx do
  @moduledoc """
  Elixir wrapper for Rust `rustybuzz` crate for OpenType shaping.

  If I/O and memory are not concerns (the font file is small, or the task infrequent), use `get/3` to access data from the shaped glyphs directly.  This creates a shaper on a one-off basis.

  If the font file-size is large and shaping is done frequently, explicitly use the `new/1` to load the font into memory. Shaping with `shape/2` is then CPU bound.  Use `stop/1` to release the memory.
  """

  use GenServer
  alias HarfbuzzEx.Native

  # --- OTP setup ---

  @doc """
  Starts a GenServer to hold the Rust instance.  Accepts a keyword list of options for configuration:
  * `:font_path`: path to the font file (typically `priv/fonts/your_font_file.ttf`)
  * `:name`: the registered name for the GenServer
  """

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    font_path = Keyword.fetch!(opts, :font_path)

    if name do
      GenServer.start_link(__MODULE__, font_path, name: name)
    else
      GenServer.start_link(__MODULE__, font_path)
    end
  end

  @doc """
  Generates the child spec, automatically using the `:name` as the `:id`
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # --- client APIs ---

  @doc """
  Input a string, shape with the font, and return a list of shaped glyphs.

  Use `:all` for a list of `%HarfbuzzEx.Glyph{}` structs, or one of `:name`, `:x_advance`, `:y_advance`, `:x_offset`, `:y_offset` for a list of string (`:name`) or integers.
  """
  def get!(font_path, string, data \\ :name) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset, :all] do
    {:ok, shaper} = new(font_path)
    {:ok, results} = shape(shaper, string)
    stop(shaper)

    case data do
      :all -> results
      _    -> results |> Enum.map(&Map.get(&1, data))
    end
  end

  def get(font_path, string, data \\ :name) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset, :all] do
    {:ok, get!(font_path, string, data)}
  end

  @doc """
  Starts a new Rust instance for the given font.

  Returns `{:ok, pid}` on success.
  """
  def new(font_path, opts \\ []) do
    opts
    |> Keyword.put(:font_path, font_path)
    |> start_link()
  end

  @doc """
  Same as `new/2` but raises on error.
  """
  def new!(font_path, opts \\ []) do
    {:ok, pid} = new(font_path, opts)
    pid
  end

  @doc """
  Shapes text using the given Shaper process, returning the full set of shaped instructions as a map of:
  * `:name` (glyph name)
  * `:x_advance`
  * `:y_advance`
  * `:x_offset`
  * `:y_offset`
  """
  def shape(server, text) do
    GenServer.call(server, {:shape, text})
  end

  @doc """
  Same as `shape/2` but raises on error.
  """
  def shape!(server, text) do
    {:ok, results} = shape(server, text)
    results
  end

  @doc """
  Shapes text using the given Shaper process, returning *only* the requested parameter as a list.  This is most useful for extracting a list of glyphnames by invoking `shape!(pid, text, :name)`.
  """
  def shape!(server, text, data) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset] do
    shape!(server, text)
    |> Enum.map(&Map.get(&1, data))
  end

  @doc """
  Same as `shape!/3` but returns an `:ok` tuple.
  """
  def shape(server, text, data) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset] do
    {:ok, shape!(server, text, data)}
  end

  @doc """
  Stops the Shaper process.
  This drops the reference to the Rust resource, allowing the BEAM
  to garbage collect the memory (font data + parsed tables).
  """
  def stop(server) do
    GenServer.stop(server)
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
