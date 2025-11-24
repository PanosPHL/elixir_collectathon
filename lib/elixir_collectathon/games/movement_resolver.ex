defmodule ElixirCollectathon.Games.MovementResolver do
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Entities.Hitbox
  alias ElixirCollectathon.Games.CollisionDetector

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
