defmodule ElixirCollectathon.Entities.Spawner do
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Letters
  alias ElixirCollectathon.Letters.Letter
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Games.Utils
  alias ElixirCollectathon.Entities.Hitbox
  alias ElixirCollectathon.Games.CollisionDetector

  @spec spawn_letter(%{optional(String.t()) => Player.t()}) :: Letter.t()
  def spawn_letter(players) do
    Letters.get_random_letter()
    |> Letter.new(generate_valid_letter_position(players))
  end

  defp generate_valid_letter_position(players) do
    {map_x, map_y} = Game.get_map_size()
    letter_size = Letter.get_letter_size()
    padding = Letter.get_padding()

    # Generate letter position and clamp to map boundaries with 24px of padding
    lx =
      :rand.uniform(map_x)
      |> Utils.clamp(padding, map_x - letter_size - padding)

    ly =
      :rand.uniform(map_y)
      |> Utils.clamp(padding, map_y - letter_size - padding)

    letter_hitbox =
      {lx, ly}
      |> Hitbox.new(letter_size)

    # If any player collides with a letter, generate another position recursively.
    # Otherwise use the generated position.
    if(
      Enum.any?(players, fn {_name, player} ->
        CollisionDetector.collides?(letter_hitbox, player.hitbox)
      end)
    ) do
      generate_valid_letter_position(players)
    else
      {lx, ly}
    end
  end
end
