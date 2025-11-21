defmodule ElixirCollectathon.Letters.Letter do
  @moduledoc """
  Represents a letter in the game.

  A letter has:
  - A character (A-Z)
  - A position on the game map as {x, y} coordinates
  """
  alias __MODULE__

  @type t() :: %__MODULE__{
          char: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

  @derive Jason.Encoder
  defstruct char: "",
            position: {0, 0}

  @letter_size 48

  def new(char, position \\ {0, 0}) do
    %Letter{char: char, position: position}
  end

  def get_letter_size() do
    @letter_size
  end
end
