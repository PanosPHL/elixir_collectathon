defmodule ElixirCollectathon.Games.Game do
  @moduledoc """
  Represents a game instance in the collectathon.

  A game contains:
  - A unique game ID
  - A tick counter for game state updates
  - A running status flag
  - A map of players participating in the game
  - The next player number to assign to new players

  The game map size is fixed at 1024x576 pixels.
  """
  alias __MODULE__

  @map_size {1024, 576}

  @derive Jason.Encoder
  defstruct game_id: "", tick_count: 0, is_running: true, players: %{}, next_player_num: 1

  @doc """
  Creates a new game instance with the given game ID.

  ## Parameters
    - `game_id` - A unique identifier for the game

  ## Examples

      iex> game = ElixirCollectathon.Games.Game.new("ABC123")
      iex> game.game_id
      "ABC123"
      iex> game.tick_count
      0
  """
  def new(game_id) do
    %Game{game_id: game_id}
  end

  @doc """
  Adds a player to the game.

  Updates the game's player map and increments the next player number.

  ## Parameters
    - `game` - The game struct to add the player to
    - `player` - The player struct to add

  ## Examples

      iex> game = ElixirCollectathon.Games.Game.new("ABC123")
      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> updated_game = ElixirCollectathon.Games.Game.add_player(game, player)
      iex> Map.has_key?(updated_game.players, "Alice")
      true
  """
  def add_player(%Game{} = game, player) do
    %Game{
      game
      | players: Map.put(game.players, player.name, player),
        next_player_num: game.next_player_num + 1
    }
  end

  @doc """
  Returns the map size as a tuple of {width, height} in pixels.

  ## Examples

      iex> ElixirCollectathon.Games.Game.get_map_size()
      {1024, 576}
  """
  def get_map_size() do
    @map_size
  end

  @doc """
  Sets the players map for a game.

  ## Parameters
    - `game` - The game struct to update
    - `players` - A map of player names to player structs

  ## Examples

      iex> game = ElixirCollectathon.Games.Game.new("ABC123")
      iex> players = %{"Alice" => ElixirCollectathon.Players.Player.new("Alice", 1)}
      iex> updated_game = ElixirCollectathon.Games.Game.set_players(game, players)
      iex> Map.has_key?(updated_game.players, "Alice")
      true
      iex> updated_game.players["Alice"].name
      "Alice"
  """
  def set_players(%Game{} = game, players) do
    %Game{game | players: players}
  end

  @doc """
  Checks if a player with the given name exists in the game.

  ## Parameters
    - `game` - The game struct to check
    - `player_name` - The name of the player to look for

  ## Examples

      iex> game = ElixirCollectathon.Games.Game.new("ABC123")
      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> game = ElixirCollectathon.Games.Game.add_player(game, player)
      iex> ElixirCollectathon.Games.Game.has_player?(game, "Alice")
      true
      iex> ElixirCollectathon.Games.Game.has_player?(game, "Bob")
      false
  """
  def has_player?(%Game{} = game, player_name) do
    Map.has_key?(game.players, player_name)
  end
end
