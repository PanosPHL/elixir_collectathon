defmodule ElixirCollectathon.Entities.Hitbox do
  alias ElixirCollectathon.Games.Game

  @moduledoc """
  Represents a hitbox for a given entity (i.e. Players, and Letters) in a game.

  A hitbox is represented as
    {x, y}          {x + width, y}
        ...............
        .             .
        .             .
        .             .
        ...............
  {x, y + height}   {x + width, y + height}
  """

  @type t() :: {non_neg_integer(), non_neg_integer(), pos_integer(), pos_integer()}

  @doc """
  Generates a new hitbox for a given entity.

  ## Parameters
  - `{x, y}` - A tuple for a given entity's position
  - `side_lw` - A side length if the entity is a square
  - `width` - The width of the entity if it is not a square
  - `height` - The height of the entity if it is not a square

  ## Examples
    iex> ElixirCollectathon.Entities.Hitbox.new({0, 0}, 40)
    {0, 0, 40, 40}
    iex> ElixirCollectathon.Entities.Hitbox.new({0, 0}, 40, 50)
    {0, 0, 40, 50}
  """
  @spec new(Game.position(), pos_integer()) :: t()
  def new({x, y}, side_lw) do
    {x, y, x + side_lw, y + side_lw}
  end

  @spec new(Game.position(), pos_integer(), pos_integer()) :: t()
  def new({x, y}, width, height) do
    {x, y, x + width, y + height}
  end
end
