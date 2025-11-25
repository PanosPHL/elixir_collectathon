defmodule ElixirCollectathon.Letters.Letter do
  @moduledoc """
  Represents a letter in the game.

  A letter has:
  - A character (A-Z)
  - A position on the game map as {x, y} coordinates
  """
  alias ElixirCollectathon.Entities.Hitbox
  alias __MODULE__

  @letter_size 48
  @padding 24

  @type t() :: %__MODULE__{
          char: String.t(),
          position: {non_neg_integer(), non_neg_integer()},
          hitbox: Hitbox.t()
        }

  @derive Jason.Encoder
  defstruct char: "",
            position: {0, 0},
            hitbox: Hitbox.new({0, 0}, @letter_size)

  @doc """
  Creates a new letter struct.

  ## Parameters
  - `char` - The character of the letter (one of E, L, I, X, R)
  - `position` - The position of the letter on the game map as {x, y} coordinates

  ## Examples
      iex> ElixirCollectathon.Letters.Letter.new("E", {0, 0})
      %ElixirCollectathon.Letters.Letter{char: "E", position: {0, 0}}
  """
  @spec new(String.t(), {non_neg_integer(), non_neg_integer()}) :: t()
  def new(char, position \\ {0, 0}) do
    %Letter{char: char, position: position, hitbox: position |> Hitbox.new(@letter_size)}
  end

  @doc """
  Returns the size of a letter.

  ## Examples
      iex> ElixirCollectathon.Letters.Letter.get_letter_size()
      48
  """
  @spec get_letter_size() :: non_neg_integer()
  def get_letter_size() do
    @letter_size
  end

  @doc """
  Returns the padding of a letter.

  ## Examples
      iex> ElixirCollectathon.Letters.Letter.get_padding()
      24
  """
  @spec get_padding() :: non_neg_integer()
  def get_padding() do
    @padding
  end
end
