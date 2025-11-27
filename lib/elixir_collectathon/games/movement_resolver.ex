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
    # Resolve X-axis movement first
    final_x =
      if check_collision_at({tx, py}, size, occupied, player_name) do
        px
      else
        tx
      end

    # Then resolve Y-axis movement using the resolved X position
    final_y =
      if check_collision_at({final_x, ty}, size, occupied, player_name) do
        py
      else
        ty
      end

    final_pos = {final_x, final_y}

    {final_pos, Hitbox.new(final_pos, size)}
  end

  # Checks if a position would collide with any occupied hitbox
  # Optimized to avoid creating intermediate hitbox until needed
  @spec check_collision_at(
          Game.position(),
          pos_integer(),
          list({String.t(), Hitbox.t()}),
          String.t()
        ) :: boolean()
  defp check_collision_at({x, y}, size, occupied, player_name) do
    test_hitbox = Hitbox.new({x, y}, size)
    CollisionDetector.collides_with_any?(test_hitbox, occupied, player_name)
  end
end
