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
  alias ElixirCollectathon.Players.Player

  @type t() :: %__MODULE__{
          game_id: String.t(),
          tick_count: non_neg_integer(),
          is_running: boolean(),
          players: %{optional(String.t()) => Player.t()},
          next_player_num: pos_integer(),
          countdown: pos_integer() | String.t()
        }

  @map_size {1024, 576}

  @derive Jason.Encoder
  defstruct game_id: "",
            tick_count: 0,
            is_running: false,
            players: %{},
            next_player_num: 1,
            countdown: 3

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

  @spec new(String.t()) :: Game.t()
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

  @spec add_player(Game.t(), Player.t()) :: Game.t()
  def add_player(%Game{} = game, %Player{} = player) do
    %Game{
      game
      | players: Map.put(game.players, player.name, player),
        next_player_num: game.next_player_num + 1
    }
  end

  @doc """
  Removes a player from the game.

  Removes the player from the player map and updates the next_player_num, should another
  player want to join the game in their stead, to the removed player's player_num.

  ## Parameters
  - `game` - The game struct to remove the player from
  - `player_name` - The name of the player/key of the players map to remove from the game

  ## Examples

      iex> game = ElixirCollectathon.Games.Game.new("ABC123")
      iex> player1 = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> player2 = ElixirCollectathon.Players.Player.new("Bob", 2)
      iex> updated_game = game
      ...> |> ElixirCollectathon.Games.Game.add_player(player1)
      ...> |> ElixirCollectathon.Games.Game.add_player(player2)
      ...> |> ElixirCollectathon.Games.Game.remove_player("Alice")
      iex> Map.has_key?(updated_game.players, "Alice")
      false
  """

  @spec remove_player(ElixirCollectathon.Games.Game.t(), String.t()) ::
          ElixirCollectathon.Games.Game.t()
  def remove_player(%Game{} = game, player_name) do
    {%Player{} = player, updated_players} = Map.pop(game.players, player_name)

    %Game{game | players: updated_players, next_player_num: player.player_num}
  end

  @doc """
  Returns the map size as a tuple of {width, height} in pixels.

  ## Examples

      iex> ElixirCollectathon.Games.Game.get_map_size()
      {1024, 576}
  """

  @spec get_map_size() :: {pos_integer(), pos_integer()}
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

  @spec set_players(Game.t(), %{optional(String.t()) => Player.t()}) :: Game.t()
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

  @spec has_player?(Game.t(), String.t()) :: boolean()
  def has_player?(%Game{} = game, player_name) do
    Map.has_key?(game.players, player_name)
  end

  @doc """
  Decrements the countdown to starting a game

  ## Parameters
  - `game` - The game struct to modify the countdown on

  ## Examples

    iex> game = ElixirCollectathon.Games.Game.new("ABC123")
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    iex> game.countdown
    "GO!"
  """

  @spec countdown_to_start(Game.t()) :: Game.t()
  def countdown_to_start(%Game{countdown: countdown} = game)
      when is_integer(countdown) and countdown > 1 do
    %Game{game | countdown: countdown - 1}
  end

  def countdown_to_start(%Game{countdown: 1} = game) do
    %Game{game | countdown: "GO!"}
  end

  @doc """
  Starts the game

  ## Parameters
  - `game` - The game struct to start

  ## Examples
    iex> game = ElixirCollectathon.Games.Game.new("ABC123")
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    ...> |> ElixirCollectathon.Games.Game.countdown_to_start()
    ...> |> ElixirCollectathon.Games.Game.start()
    iex> game.is_running
    true
  """

  @spec start(Game.t()) :: Game.t()
  def start(%Game{} = game) do
    %Game{game | is_running: true}
  end
end
