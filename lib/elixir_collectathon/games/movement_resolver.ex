defmodule ElixirCollectathon.Games.MovementResolver do
  @moduledoc """
  Resolves movement for players within the game
  """

  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Entities.Hitbox
  alias ElixirCollectathon.Games.CollisionDetector

  @doc """
  Resolves player movement on each frame of the game

  Attempts to move the player to the target position, checking for collisions
  along both X and Y axes separately to allow sliding along obstacles.

  ## Parameters
  - `player` - The player who's movement to resolve
  - `{tx, ty}` - Target position tuple
  - `occupied` - List of player name and hitbox tuples
  - `size` - size of the entity whose movement is being resolved, in this case players

  ## Examples

  When no collisions occur, the player moves to the target position:

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> target = {10, 20}
      iex> occupied = []
      iex> size = 32
      iex> {final_pos, _final_hitbox} = ElixirCollectathon.Games.MovementResolver.resolve(player, target, occupied, size)
      iex> final_pos
      {10, 20}

  When a collision blocks movement, the player stops at the blocked axis:

      iex> size = ElixirCollectathon.Players.Player.get_player_size()
      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> bob_hitbox = ElixirCollectathon.Entities.Hitbox.new({10, 0}, size)
      iex> occupied = [{"Bob", bob_hitbox}]
      iex> target = {10, 20}
      iex> {final_pos, _final_hitbox} = ElixirCollectathon.Games.MovementResolver.resolve(player, target, occupied, size)
      iex> final_pos
      {0, 0}
  """

  @spec resolve(
          Player.t(),
          Game.position(),
          list({String.t(), Hitbox.t()}),
          pos_integer()
        ) :: {Game.position(), Hitbox.t()}
  def resolve(%Player{position: {px, py}, name: player_name}, {tx, ty}, occupied, size) do
    new_x_hitbox =
      Hitbox.new({tx, py}, size)

    final_x =
      if CollisionDetector.collides_with_any?(new_x_hitbox, occupied, player_name) do
        px
      else
        tx
      end

    new_y_hitbox =
      Hitbox.new({final_x, ty}, size)

    final_y =
      if CollisionDetector.collides_with_any?(new_y_hitbox, occupied, player_name) do
        py
      else
        ty
      end

    final_pos = {final_x, final_y}

    {final_pos, Hitbox.new(final_pos, size)}
  end
end
