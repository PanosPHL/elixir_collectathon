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

  alias ElixirCollectathon.Letters.Letter
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Games.Utils
  alias ElixirCollectathon.Games.CollisionDetector
  alias ElixirCollectathon.Entities.Spawner
  alias ElixirCollectathon.Games.MovementResolver
  alias __MODULE__

  @type position() :: {non_neg_integer(), non_neg_integer()}

  @type t() :: %__MODULE__{
          game_id: String.t(),
          tick_count: non_neg_integer(),
          is_running: boolean(),
          players: %{optional(String.t()) => Player.t()},
          next_player_num: pos_integer(),
          countdown: pos_integer() | String.t(),
          current_letter: Letter.t() | nil,
          winner: String.t() | nil,
          timer_ref: :timer.tref() | nil
        }

  @map_size {1024, 576}
  @movement_speed 15

  @derive {Jason.Encoder, except: [:tick_count, :next_player_num, :countdown, :timer_ref]}
  defstruct game_id: "",
            tick_count: 0,
            is_running: false,
            players: %{},
            next_player_num: 1,
            countdown: 3,
            current_letter: nil,
            winner: nil,
            timer_ref: nil

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
      iex> player = ElixirCollectathon.Entities.Spawner.spawn_player("Alice", 1)
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
  Spawns a player with the correct position in the game.

  ## Parameters
  - `game` - The game struct the player should be spawned in
  - `player_name` - The name of the player to spawn
  - `player_num` - The player number (i.e. 1, 2, 3, 4) of the player to spawn

  ## Examples
    iex> game = ElixirCollectathon.Games.Game.new("ABC123")
    iex> updated_game = ElixirCollectathon.Games.Game.spawn_player(game, "Alice", 1)
    iex> Map.has_key?(updated_game.players, "Alice")
    true
  """
  @spec spawn_player(Game.t(), String.t(), Player.player_num()) :: Game.t()
  def spawn_player(%Game{} = game, player_name, player_num) do
    game
    |> add_player(Spawner.spawn_player(player_name, player_num))
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
      iex> player1 = ElixirCollectathon.Entities.Spawner.spawn_player("Alice", 1)
      iex> player2 = ElixirCollectathon.Entities.Spawner.spawn_player("Bob", 2)
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
    {%Player{player_num: removed_player_num}, updated_players} =
      Map.pop!(game.players, player_name)

    %Game{game | players: updated_players, next_player_num: removed_player_num}
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
      iex> players = %{"Alice" => ElixirCollectathon.Entities.Spawner.spawn_player("Alice", 1)}
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
      iex> player = ElixirCollectathon.Entities.Spawner.spawn_player("Alice", 1)
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

  @spec start(Game.t(), :timer.tref() | nil) :: Game.t()
  def start(%Game{} = game, timer_ref \\ nil) do
    game =
      game
      |> spawn_letter()

    %Game{game | is_running: true, timer_ref: timer_ref}
  end

  @doc """
  Updates the velocity of a player.

  ## Parameters
  - `game` - The game struct to update
  - `player_name` - The name of the player to update
  - `velocity` - A tuple {x, y} representing the velocity vector

  ## Examples
  iex> game = ElixirCollectathon.Games.Game.new("ABC123")
  ...> |> ElixirCollectathon.Games.Game.spawn_player("Alice", 1)
  ...> |> ElixirCollectathon.Games.Game.update_player_velocity("Alice", {1, 0})
  iex> %ElixirCollectathon.Players.Player{velocity: velocity} = Map.get(game.players, "Alice")
  iex> velocity
  {1, 0}
  """

  @spec update_player_velocity(Game.t(), String.t(), Player.velocity()) :: Game.t()
  def update_player_velocity(%Game{} = game, player_name, velocity) do
    players = Map.update!(game.players, player_name, &Player.set_velocity(&1, velocity))

    %Game{game | players: players}
  end

  @doc """
  Updates the game state by:
  - Updating player positions based on their velocities
  - Checking for letter collisions and awarding letters to players
  - Incrementing the tick count
  ## Parameters
  - `game` - The game struct to update

  ## Examples

  iex> game = ElixirCollectathon.Games.Game.new("ABC123")
  iex> updated_game = ElixirCollectathon.Games.Game.update_game_state(game)
  iex> updated_game.tick_count
  1
  """

  @spec update_game_state(Game.t()) :: Game.t()
  def update_game_state(%Game{} = game) do
    game
    |> update_player_positions()
    |> check_letter_collisions()
    |> check_winner()
    |> increment_tick_count()
  end

  # Calculates the target position and hitbox, checks against currently occupied positions
  # and hitbox. Collisions are done on a body-blocking or sliding behavior. X movement is preserved on Y
  # collisions and Y movement is preserved on X collisions.
  @spec update_player_positions(Game.t()) :: Game.t()
  defp update_player_positions(%Game{players: players} = game) do
    ordered = Enum.to_list(players)
    player_size = Player.get_player_size()

    initial_occupied =
      Enum.map(players, fn {name, %Player{hitbox: player_hitbox}} ->
        {name, player_hitbox}
      end)

    {new_players, _occ} =
      Enum.reduce(ordered, {%{}, initial_occupied}, fn {name,
                                                        %Player{
                                                          position: player_position,
                                                          velocity: player_velocity
                                                        } = player},
                                                       {acc, occupied} ->
        target_position = calculate_target_position(player_position, player_velocity)

        {updated_position, hitbox} =
          MovementResolver.resolve(player, target_position, occupied, player_size)

        updated_player = Player.set_position(player, updated_position)

        {
          Map.put(acc, name, updated_player),
          [{name, hitbox} | occupied]
        }
      end)

    set_players(game, new_players)
  end

  # Calculates the target position for a given player based on its current position and velocity
  @spec calculate_target_position(Game.position(), Player.velocity()) ::
          Game.position()
  defp calculate_target_position(player_position, player_velocity) do
    {x, y} = player_position
    {vx, vy} = player_velocity

    {map_x, map_y} = @map_size
    player_size = Player.get_player_size()

    # Calculate movement from position and velocity, and "trunc" back to integer
    # Clamp that result to the map bounds minus the width/height of the player box
    {
      Utils.clamp(trunc(x + vx * @movement_speed), 0, map_x - player_size),
      Utils.clamp(trunc(y + vy * @movement_speed), 0, map_y - player_size)
    }
  end

  # Checks if a player collides with a letter and adds it to their inventory
  # Preferentially treats players who joined the game first
  # TO DO: Refactor to treat players on frame they adjusted their velocity
  @spec check_letter_collisions(Game.t()) :: Game.t()
  defp check_letter_collisions(%Game{current_letter: letter, players: players} = game)
       when is_map(letter) do
    case Enum.find(players, fn {_name, player} ->
           CollisionDetector.collides?(letter.hitbox, player.hitbox)
         end) do
      {_, player} ->
        award_letter_to_player(game, player)

      nil ->
        game
    end
  end

  defp check_letter_collisions(%Game{} = game) do
    game
  end

  # Checks if a player has won and sets them as the
  # winner in the game state/struct
  @spec check_winner(Game.t()) :: Game.t()
  defp check_winner(%Game{players: players} = game) do
    case Enum.find(players, fn {_name, player} ->
           Player.has_won?(player)
         end) do
      {name, _player} ->
        game
        |> declare_winner(name)

      nil ->
        game
    end
  end

  # Sets the declared winner in the game struct
  @spec declare_winner(Game.t(), String.t()) :: Game.t()
  defp declare_winner(%Game{} = game, winner) when not is_nil(winner) do
    %Game{game | winner: winner}
  end

  @spec increment_tick_count(Game.t()) :: Game.t()
  defp increment_tick_count(%Game{tick_count: tick_count} = game) do
    %Game{game | tick_count: tick_count + 1}
  end

  @spec award_letter_to_player(Game.t(), Player.t()) :: Game.t()
  defp award_letter_to_player(%Game{} = game, %Player{} = player) do
    # Update player's collected letters
    updated_player =
      Player.add_collected_letter(player, game.current_letter.char)

    updated_players =
      Map.put(game.players, player.name, updated_player)

    %Game{game | players: updated_players, current_letter: nil}
  end

  @doc """
  Spawns a letter in a random place on the map that is not currently occupied by a player

  ## Parameters
  - `game` - The game struct to spawn a letter in

  ## Examples
    iex> game = ElixirCollectathon.Games.Game.new("ABC123")
    iex> updated_game = ElixirCollectathon.Games.Game.spawn_letter(game)
    iex> updated_game.current_letter != nil
    true
  """
  @spec spawn_letter(Game.t()) :: Game.t()
  def spawn_letter(%Game{} = game) do
    %Game{game | current_letter: Spawner.spawn_letter(game.players)}
  end

  @doc """
  Stops the game currently in place

  ## Parameters
  - `game` - The game struct to stop

  ## Examples
    iex> game = ElixirCollectathon.Games.Game.new("ABC123")
    ...> |> ElixirCollectathon.Games.Game.start()
    iex> game.is_running
    true
    iex> game = ElixirCollectathon.Games.Game.stop(game)
    iex> game.is_running
    false
    iex> game.timer_ref
    nil
  """

  @spec stop(Game.t()) :: Game.t()
  def stop(%Game{} = game) do
    %Game{game | is_running: false, timer_ref: nil}
  end
end
