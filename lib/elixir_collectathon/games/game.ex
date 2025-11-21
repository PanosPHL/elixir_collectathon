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

  alias ElixirCollectathon.Letters
  alias ElixirCollectathon.Letters.Letter
  alias __MODULE__
  alias ElixirCollectathon.Players.Player

  @type t() :: %__MODULE__{
          game_id: String.t(),
          tick_count: non_neg_integer(),
          is_running: boolean(),
          players: %{optional(String.t()) => Player.t()},
          next_player_num: pos_integer(),
          countdown: pos_integer() | String.t(),
          current_letter: Letter.t() | nil
        }

  @map_size {1024, 576}
  @box_lw 40
  @movement_speed 15

  @derive Jason.Encoder
  defstruct game_id: "",
            tick_count: 0,
            is_running: false,
            players: %{},
            next_player_num: 1,
            countdown: 3,
            current_letter: nil

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
    game =
      game
      |> spawn_letter()

    %Game{game | is_running: true}
  end

  def update_game_state(%Game{} = game) do
    game
    |> update_player_positions()
    |> check_letter_collisions()
    |> increment_tick_count()
  end

  def spawn_letter(%Game{} = game) do
    letter =
      Letters.get_random_letter()
      |> Letter.new(generate_valid_letter_position(game))

    %Game{game | current_letter: letter}
  end

  defp check_letter_collisions(%Game{} = game) when is_map(game.current_letter) do
    letter = game.current_letter

    case Enum.find(game.players, fn {_id, player} ->
           letter_collides_with_player?(letter.position, player.position)
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

  defp check_player_collisions(%Game{} = game) do
    player_list = Map.values(game.players)

    for i <- 0..(length(player_list) - 2) do
      for j <- (i + 1)..(length(player_list) - 1) do
        player_a = Enum.at(player_list, i)
        player_b = Enum.at(player_list, j)

        if player_collides_with_player?(player_a.position, player_b.position) do
          #
        end
      end
    end
  end

  defp award_letter_to_player(%Game{} = game, %Player{} = player) do
    # Update player's collected letters
    updated_player =
      Player.add_collected_letter(player, game.current_letter.char)

    updated_players =
      Map.put(game.players, player.name, updated_player)

    %Game{game | players: updated_players, current_letter: nil}
  end

  defp letter_collides_with_player?({lx, ly}, {px, py}) do
    letter_size = Letter.get_letter_size()
    player_size = Player.get_player_size()

    collides?({lx, ly, letter_size}, {px, py, player_size})
  end

  defp player_collides_with_player?({ax, ay}, {bx, by}) do
    player_size = Player.get_player_size()

    collides?({ax, ay, player_size}, {bx, by, player_size})
  end

  def collides?({ax, ay, asize}, {bx, by, bsize}) do
    abs(ax - bx) < bsize / 2 + asize / 2 and
      abs(ay - by) < bsize / 2 + asize / 2
  end

  @spec update_player_position(Player.t()) :: Player.t()
  defp update_player_position(
         %Player{position: player_position, velocity: player_velocity} = player
       ) do
    {x, y} = player_position
    {vx, vy} = player_velocity

    map_size = Game.get_map_size()

    new_position = {
      clamp(x + vx * @movement_speed, 0, elem(map_size, 0) - @box_lw),
      clamp(y + vy * @movement_speed, 0, elem(map_size, 1) - @box_lw)
    }

    Player.set_position(player, new_position)
  end

  defp update_player_positions(%Game{} = game) do
    updated_players =
      Map.new(game.players, fn {player_name, player} ->
        {player_name, update_player_position(player)}
      end)

    %Game{game | players: updated_players}
  end

  defp generate_valid_letter_position(%Game{} = game) do
    {map_x, map_y} = get_map_size()
    letter_size = Letter.get_letter_size()

    lx =
      :rand.uniform(map_x)
      |> clamp(letter_size, map_x - letter_size)

    ly =
      :rand.uniform(map_y)
      |> clamp(letter_size, map_y - letter_size)

    if(
      Enum.any?(game.players, fn {_name, player} ->
        letter_collides_with_player?({lx, ly}, player.position)
      end)
    ) do
      generate_valid_letter_position(game)
    else
      {lx, ly}
    end
  end

  defp increment_tick_count(%Game{tick_count: tick_count} = game) do
    %Game{game | tick_count: tick_count + 1}
  end

  @spec clamp(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp clamp(v, min, max), do: v |> max(min) |> min(max)
end
