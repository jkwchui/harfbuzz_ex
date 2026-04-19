defmodule HarfbuzzEx.Shaper.Glyph do
  @moduledoc """
  Represents a shaped glyph.
  """
  defstruct [:name, :x_advance, :y_advance, :x_offset, :y_offset]

  @type t :: %__MODULE__{
          name: String.t(),
          x_advance: integer(),
          y_advance: integer(),
          x_offset: integer(),
          y_offset: integer()
        }
end
