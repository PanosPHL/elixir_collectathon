defmodule ElixirCollectathon.Games.CollisionDetector do
  @moduledoc """
  Handles the collision detection of two entities in the game (i.e. Player to Player, Player to Letter)
  """
  alias ElixirCollectathon.Entities.Hitbox

  @doc """
  Checks between the collision of two hitboxes

  ## Parameters
  - `{ax1, ay1, ax2, ay2}` - A tuple representing a hitbox
  - `{bx1, by1, bx2, by2}` - A tuple representing another hitbox

  ## Examples
    iex> hitbox1 = ElixirCollectathon.Entities.Hitbox.new({0, 0}, 40)
    iex> hitbox2 = ElixirCollectathon.Entities.Hitbox.new({0, 10}, 40)
    iex> hitbox3 = ElixirCollectathon.Entities.Hitbox.new({50, 50}, 40)
    iex> ElixirCollectathon.Games.CollisionDetector.collides?(hitbox1, hitbox2)
    true
    iex> ElixirCollectathon.Games.CollisionDetector.collides?(hitbox1, hitbox3)
    false
  """

  @spec collides?(Hitbox.t(), Hitbox.t()) :: boolean()
  def collides?({ax1, ay1, ax2, ay2}, {bx1, by1, bx2, by2}) do
    not (ax2 <= bx1 or ax1 >= bx2 or ay2 <= by1 or ay1 >= by2)
  end

  @doc """
  Checks if a player collides with any position occupied by another player

  ## Parameters
  - `hitbox` - The hitbox of the current player you are checking
  - `occupied` - A list of the hitboxes of all the other players
  - `self` - The player's name of the current player you are checking

  ## Examples
    iex> hitbox = ElixirCollectathon.Entities.Hitbox.new({10, 10}, 40)
    iex> occupied1 = [{"Steve", ElixirCollectathon.Entities.Hitbox.new({0, 0}, 40)}]
    iex> occupied2 = [{"Bob", ElixirCollectathon.Entities.Hitbox.new({400, 400}, 40)}]
    iex> ElixirCollectathon.Games.CollisionDetector.collides_with_any?(hitbox, occupied1, "Alice")
    true
    iex> ElixirCollectathon.Games.CollisionDetector.collides_with_any?(hitbox, occupied2, "Alice")
    false
  """
  @spec collides_with_any?(Hitbox.t(), list({String.t(), Hitbox.t()}), String.t()) :: boolean()
  def collides_with_any?(hitbox, occupied, self) do
    Enum.any?(occupied, fn {name, other_hitbox} ->
      self != name and collides?(hitbox, other_hitbox)
    end)
  end
end
