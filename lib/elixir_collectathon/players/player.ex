defmodule ElixirCollectathon.Players.Player do
  @moduledoc """
  Represents a player in the game.

  A player has:
  - A unique name
  - A color (red, blue, yellow, or green) based on player number
  - A position on the game map as {x, y} coordinates
  - A velocity vector as {x, y} for movement
  - An inventory string for collected items

  Players are positioned at the corners of the map when created:
  - Player 1: top-left
  - Player 2: top-right
  - Player 3: bottom-left
  - Player 4: bottom-right
  """
  alias ElixirCollectathon.Games.Game
  alias __MODULE__

  @type t() :: %__MODULE__{
          color: String.t(),
          name: String.t(),
          position: {non_neg_integer(), non_neg_integer()},
          velocity: {non_neg_integer(), non_neg_integer()},
          inventory: list(String.t() | nil),
          player_num: pos_integer()
        }

  @player_lw 40

  @player_colors %{
    1 => "red",
    2 => "blue",
    3 => "yellow",
    4 => "green"
  }

  @derive Jason.Encoder
  defstruct color: "red",
            name: "",
            position: {0, 0},
            velocity: {0, 0},
            inventory: [nil, nil, nil, nil, nil, nil],
            player_num: 1

  @doc """
  Creates a new player with the given name and player number.

  The player is positioned at a corner of the map based on their player number.
  Player colors are assigned automatically based on player number.

  ## Parameters
    - `name` - The player's name
    - `player_num` - The player number (1-4), determines color and starting position

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> player.name
      "Alice"
      iex> player.color
      "red"
      iex> player.position
      {0, 0}
  """

  @spec new(String.t(), pos_integer()) :: Player.t()
  def new(name, player_num \\ 1) do
    {map_x, map_y} = Game.get_map_size()

    position =
      case player_num do
        1 -> {0, 0}
        2 -> {map_x - @player_lw, 0}
        3 -> {0, map_y - @player_lw}
        4 -> {map_x - @player_lw, map_y - @player_lw}
      end

    %Player{
      name: name,
      color: @player_colors[player_num],
      position: position,
      player_num: player_num
    }
  end

  @doc """
  Updates the velocity of a player.

  ## Parameters
    - `player` - The player struct to update
    - `velocity` - A tuple {x, y} representing the velocity vector

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> updated = ElixirCollectathon.Players.Player.set_velocity(player, {1, 0})
      iex> updated.velocity
      {1, 0}
  """

  @spec set_velocity(Player.t(), {integer(), integer()}) :: Player.t()
  def set_velocity(%Player{} = player, velocity) do
    %Player{player | velocity: velocity}
  end

  @doc """
  Updates the position of a player.

  ## Parameters
    - `player` - The player struct to update
    - `position` - A tuple {x, y} representing the position coordinates

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1)
      iex> updated = ElixirCollectathon.Players.Player.set_position(player, {100, 200})
      iex> updated.position
      {100, 200}
  """

  @spec set_position(Player.t(), {non_neg_integer(), non_neg_integer()}) :: Player.t()
  def set_position(%Player{} = player, position) do
    %Player{player | position: position}
  end
end
