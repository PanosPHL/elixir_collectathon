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
  alias ElixirCollectathon.Entities.Hitbox
  alias __MODULE__

  @player_lw 40

  @player_colors %{
    1 => "red",
    2 => "blue",
    3 => "yellow",
    4 => "green"
  }

  @type velocity() :: {float(), float()}
  @type inventory() :: list(String.t() | nil)
  @type player_num() :: 1 | 2 | 3 | 4
  @type t() :: %__MODULE__{
          color: String.t(),
          name: String.t(),
          position: Game.position(),
          hitbox: Hitbox.t(),
          velocity: velocity(),
          inventory: inventory(),
          player_num: player_num()
        }

  @derive {Jason.Encoder, except: [:hitbox, :velocity]}
  defstruct color: "red",
            name: "",
            position: {0, 0},
            hitbox: Hitbox.new({0, 0}, @player_lw),
            velocity: {0.0, 0.0},
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

  @spec new(String.t(), player_num(), Game.position()) :: Player.t()
  def new(name, player_num, position) do
    %Player{
      name: name,
      color: Map.fetch!(@player_colors, player_num),
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

  @spec set_velocity(Player.t(), Player.velocity()) :: Player.t()
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

  @spec set_position(Player.t(), Game.position()) :: Player.t()
  def set_position(%Player{} = player, position) do
    hitbox =
      position
      |> Hitbox.new(@player_lw)

    %Player{player | position: position, hitbox: hitbox}
  end

  @doc """
  Replace a player's entire inventory with the provided inventory list.

  This is a low-level helper used by other Player functions. The `inventory`
  is expected to be a list of strings (letter characters) or `nil` values with
  the same length as the player's inventory (six slots by default).

  ## Examples
    iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
    iex> inventory = ["E", nil, "I", nil, nil, nil]
    iex> updated = ElixirCollectathon.Players.Player.set_inventory(player, inventory)
    iex> updated.inventory
    ["E", nil, "I", nil, nil, nil]
  """

  @spec set_inventory(Player.t(), Player.inventory()) :: Player.t()
  def set_inventory(%Player{} = player, inventory) do
    %Player{player | inventory: inventory}
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
  @spec add_collected_letter(Player.t(), String.t()) :: Player.t()
  def add_collected_letter(%Player{inventory: inventory} = player, letter) do
    updated_inventory = place_letter_in_inventory(inventory, letter)
    Player.set_inventory(player, updated_inventory)
  end

  # Places a letter in the correct position in the inventory.
  # Special handling for "I" which can occupy positions 2 or 4.
  @spec place_letter_in_inventory(Player.inventory(), String.t()) :: Player.inventory()
  defp place_letter_in_inventory(inventory, "E"), do: List.replace_at(inventory, 0, "E")
  defp place_letter_in_inventory(inventory, "L"), do: List.replace_at(inventory, 1, "L")

  defp place_letter_in_inventory(inventory, "I") do
    if Enum.at(inventory, 2) == nil do
      List.replace_at(inventory, 2, "I")
    else
      List.replace_at(inventory, 4, "I")
    end
  end

  defp place_letter_in_inventory(inventory, "X"), do: List.replace_at(inventory, 3, "X")
  defp place_letter_in_inventory(inventory, "R"), do: List.replace_at(inventory, 5, "R")

  @spec remove_letter_from_inventory(Player.t(), String.t()) :: Player.t()
  def remove_letter_from_inventory(%Player{inventory: inventory} = player, letter) do
    # Remove from the rightmost position (highest index) to match removal priority
    case find_last_index(inventory, letter) do
      nil ->
        player

      index ->
        updated_inventory = List.replace_at(inventory, index, nil)
        Player.set_inventory(player, updated_inventory)
    end
  end

  # Finds the rightmost index of a letter in the inventory
  @spec find_last_index(Player.inventory(), String.t()) :: non_neg_integer() | nil
  defp find_last_index(inventory, letter) do
    inventory
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.find_value(fn {char, index} -> char == letter && index end)
  end

  @doc """
  Returns a boolean indicating whether a given player has won the game they are playing

  ## Parameters
  - `player` - The player struct to check for victory against

  ## Examples
    iex> player = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
    iex> ElixirCollectathon.Players.Player.has_won?(player)
    false

    iex> player = ElixirCollectathon.Players.Player.new("Bob", 1, {0, 0})
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("E")
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("L")
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("I")
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("X")
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("I")
    ...> |> ElixirCollectathon.Players.Player.add_collected_letter("R")
    iex> ElixirCollectathon.Players.Player.has_won?(player)
    true
  """

  @spec has_won?(Player.t()) :: boolean()
  def has_won?(%Player{inventory: inventory}) do
    inventory == ~w(E L I X I R)
  end

  @doc """
  Returns the size of a player.

  ## Examples
      iex> ElixirCollectathon.Players.Player.get_player_size()
      40
  """
  @spec get_player_size() :: pos_integer()
  def get_player_size() do
    @player_lw
  end
end
