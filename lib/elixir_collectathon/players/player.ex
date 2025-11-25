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
  alias ElixirCollectathon.Entities.Hitbox
  alias __MODULE__

  @player_lw 40

  @player_colors %{
    1 => "red",
    2 => "blue",
    3 => "yellow",
    4 => "green"
  }

  @type player_num() :: 1 | 2 | 3 | 4
  @type t() :: %__MODULE__{
          color: String.t(),
          name: String.t(),
          position: {non_neg_integer(), non_neg_integer()},
          hitbox: Hitbox.t(),
          velocity: {float(), float()},
          inventory: list(String.t() | nil),
          player_num: 1 | 2 | 3 | 4
        }

  @derive Jason.Encoder
  defstruct color: "red",
            name: "",
            position: {0, 0},
            hitbox: Hitbox.new({0, 0}, @player_lw),
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

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> player.name
      "Alice"
      iex> player.color
      "red"
      iex> player.position
      {0, 0}
  """

  @spec new(String.t(), player_num(), {non_neg_integer(), non_neg_integer()}) :: t()
  def new(name, player_num \\ 1, position) do
    %Player{
      name: name,
      color: @player_colors[player_num],
      position: position,
      hitbox:
        position
        |> Hitbox.new(@player_lw),
      player_num: player_num
    }
  end

  @doc """
  Updates the velocity of a player.

  ## Parameters
    - `player` - The player struct to update
    - `velocity` - A tuple {x, y} representing the velocity vector

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> updated = ElixirCollectathon.Players.Player.set_velocity(player, {1, 0})
      iex> updated.velocity
      {1, 0}
  """

  @spec set_velocity(t(), {integer(), integer()}) :: t()
  def set_velocity(%Player{} = player, velocity) do
    %Player{player | velocity: velocity}
  end

  @doc """
  Updates the position of a player.

  ## Parameters
    - `player` - The player struct to update
    - `position` - A tuple {x, y} representing the position coordinates

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> updated = ElixirCollectathon.Players.Player.set_position(player, {100, 200})
      iex> updated.position
      {100, 200}
  """

  @spec set_position(t(), {non_neg_integer(), non_neg_integer()}) :: t()
  def set_position(%Player{} = player, position) do
    hitbox =
      position
      |> Hitbox.new(@player_lw)

    %Player{player | position: position, hitbox: hitbox}
  end

  @doc """
  Adds a collected letter to the player's inventory.

  ## Parameters
    - `player` - The player struct to update
    - `letter` - The letter to add to the inventory

  ## Examples

      iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
      iex> updated = ElixirCollectathon.Players.Player.add_collected_letter(player, "E")
      iex> updated.inventory
      ["E", nil, nil, nil, nil, nil]
  """
  @spec add_collected_letter(t(), String.t()) :: t()
  def add_collected_letter(%Player{} = player, letter) do
    updated_inventory =
      case letter do
        "E" ->
          List.replace_at(player.inventory, 0, letter)

        "L" ->
          List.replace_at(player.inventory, 1, letter)

        "I" ->
          if Enum.at(player.inventory, 2) == nil do
            List.replace_at(player.inventory, 2, letter)
          else
            List.replace_at(player.inventory, 4, letter)
          end

        "X" ->
          List.replace_at(player.inventory, 3, letter)

        "R" ->
          List.replace_at(player.inventory, 5, letter)
      end

    %Player{player | inventory: updated_inventory}
  end

  @doc """
  Returns the size of a player.

  ## Examples
      iex> ElixirCollectathon.Players.Player.get_player_size()
      40
  """
  @spec get_player_size() :: non_neg_integer()
  def get_player_size() do
    @player_lw
  end
end
