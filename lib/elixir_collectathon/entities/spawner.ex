defmodule ElixirCollectathon.Entities.Spawner do
  @moduledoc """
  Responsible for spawning new entities (i.e. Players and Letters) into a game.
  """

  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Letters
  alias ElixirCollectathon.Letters.Letter
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Games.Utils
  alias ElixirCollectathon.Entities.Hitbox
  alias ElixirCollectathon.Games.CollisionDetector

  @doc """
  Spawns a letter entity into a game

  ## Parameters
  - `players` - The map of players on a %Game{} struct

  ## Examples
    iex> %ElixirCollectathon.Games.Game{players: players} = ElixirCollectathon.Games.Game.new("ABC123")
    iex> letter = ElixirCollectathon.Entities.Spawner.spawn_letter(players)
    iex> is_nil(letter)
    false
  """

  @spec spawn_letter(Game.players()) :: Letter.t()
  def spawn_letter(players) do
    Letters.get_random_letter()
    |> Letter.new(generate_valid_letter_position(players))
  end

  @spec generate_valid_letter_position(Game.players()) :: Game.position()
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

  @doc """
  Spawns a player entity into a game

  ## Parameters
  - `player_name` - The name of the player to spawn
  - `player_num` - The number of the player (i.e. 1, 2, 3, 4) to spawn

  ## Examples
    iex> player = ElixirCollectathon.Entities.Spawner.spawn_player("Alice", 1)
    iex> player.name
    "Alice"
    iex> player.position
    {0, 0}
  """

  @spec spawn_player(String.t(), Player.player_num()) :: Player.t()
  def spawn_player(player_name, player_num) do
    {map_x, map_y} = Game.get_map_size()
    player_size = Player.get_player_size()

    position =
      case player_num do
        1 -> {0, 0}
        2 -> {map_x - player_size, 0}
        3 -> {0, map_y - player_size}
        4 -> {map_x - player_size, map_y - player_size}
      end

    Player.new(player_name, player_num, position)
  end
end
