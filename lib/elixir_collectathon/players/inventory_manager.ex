defmodule ElixirCollectathon.Players.InventoryManager do
  @moduledoc """
  Responsible for managing players' inventory upon letter collection in a game.
  """

  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Letters.Letter

  @doc """
  Handles game logic for when a player collects a letter in a game. When a player does not have the
  max allowable amount of a letter in their inventory, it adds their letter to their inventory. Otherwise,
  it removes it from the inventory of another random player should anyone else have it.

  ## Parameters
  - `game` - The game struct of the game to update
  - `player` - The player who collected the letter

  ## Examples
  When the collecting player does not have the max allowed amount in their inventory, it adds it to
  their inventory.

    iex> p1 = ElixirCollectathon.Players.Player.new("Alice", 1, {0, 0})
    iex> p2 = ElixirCollectathon.Players.Player.new("Bob", 2, {0, 0})
    iex> players = %{"Alice" => p1, "Bob" => p2}
    iex> game = ElixirCollectathon.Games.Game.new("g") |> ElixirCollectathon.Games.Game.set_players(players)
    iex> game = %{game | current_letter: ElixirCollectathon.Letters.Letter.new("E")}
    iex> updated = ElixirCollectathon.Players.InventoryManager.handle_collected_letter(game, p1)
    iex> updated.players["Alice"].inventory
    ["E", nil, nil, nil, nil, nil]
    iex> updated.current_letter
    nil

  When the collecting player already has the max allowed amount and no other player has the letter,
  the inventory remains unchanged and the letter is cleared from the game:

    iex> p1 = %ElixirCollectathon.Players.Player{p1 | inventory: [nil, nil, "I", nil, "I", nil]} = ElixirCollectathon.Players.Player.new("Alice", 1, {0,0}) |> (fn p -> %ElixirCollectathon.Players.Player{p | inventory: [nil, nil, "I", nil, "I", nil]} end).()
    iex> p2 = ElixirCollectathon.Players.Player.new("Bob", 2, {0, 0})
    iex> players = %{"Alice" => p1, "Bob" => p2}
    iex> game = ElixirCollectathon.Games.Game.new("g") |> ElixirCollectathon.Games.Game.set_players(players)
    iex> game = %{game | current_letter: ElixirCollectathon.Letters.Letter.new("I")}
    iex> updated = ElixirCollectathon.Players.InventoryManager.handle_collected_letter(game, p1)
    iex> updated.players["Alice"].inventory
    [nil, nil, "I", nil, "I", nil]
    iex> updated.current_letter
    nil

  If the collecting player already has the max and another player holds that letter, the
  letter is removed from that other player's inventory (here Bob):

    iex> p1 = %ElixirCollectathon.Players.Player{p1 | inventory: ["E", nil, nil, nil, nil, nil]} = ElixirCollectathon.Players.Player.new("Alice", 1, {0,0}) |> (fn p -> %ElixirCollectathon.Players.Player{p | inventory: ["E", nil, nil, nil, nil, nil]} end).()
    iex> p2 = %ElixirCollectathon.Players.Player{p2 | inventory: ["E", nil, nil, nil, nil, nil]} = ElixirCollectathon.Players.Player.new("Bob", 2, {0,0}) |> (fn p -> %ElixirCollectathon.Players.Player{p | inventory: ["E", nil, nil, nil, nil, nil]} end).()
    iex> players = %{"Alice" => p1, "Bob" => p2}
    iex> game = ElixirCollectathon.Games.Game.new("g") |> ElixirCollectathon.Games.Game.set_players(players)
    iex> game = %{game | current_letter: ElixirCollectathon.Letters.Letter.new("E")}
    iex> updated = ElixirCollectathon.Players.InventoryManager.handle_collected_letter(game, p1)
    iex> updated.players["Bob"].inventory
    [nil, nil, nil, nil, nil, nil]
    iex> updated.current_letter
    nil
  """
  @spec handle_collected_letter(Game.t(), Player.t()) :: Game.t()
  def handle_collected_letter(
        %Game{current_letter: %Letter{char: char}, players: players} = game,
        %Player{inventory: inventory, name: name} = player
      ) do
    # Check if players has the max allowable amount of a letter in their
    # inventory (i.e. 2 for "I", 1 for all other characters)
    %Player{name: updated_player_name} =
      updated_player =
      if has_max_letter_in_inventory?(inventory, char) do
        # Check if other players even have that letter in their inventory
        case filter_players_by_letter_in_inventory(players, name, char) do
          # If not, return the original player who collected the letter unmodified
          [] ->
            player

          # If so, pick a random player and remove that letter from their inventory
          other_players ->
            {_other_name, other_player} =
              Enum.random(other_players)

            Player.remove_letter_from_inventory(other_player, char)
        end
      else
        # If the player does not have the max allowable amount of a letter
        # in their inventory, add it to the inventory
        Player.add_collected_letter(player, char)
      end

    updated_players = Map.put(players, updated_player_name, updated_player)

    game
    |> Game.set_players(updated_players)
    |> then(fn g -> %{g | current_letter: nil} end)
  end

  @spec filter_players_by_letter_in_inventory(
          Game.players(),
          String.t(),
          String.t()
        ) :: list(Player.t())
  defp filter_players_by_letter_in_inventory(players, self, char) do
    Enum.filter(players, fn {other_name, %Player{inventory: other_inventory}} ->
      self != other_name and Enum.any?(other_inventory, &(&1 == char))
    end)
  end

  @spec has_max_letter_in_inventory?(Player.inventory(), String.t()) :: boolean()
  defp has_max_letter_in_inventory?(inventory, char) do
    Enum.count(inventory, fn letter -> letter == char end) >=
      case char do
        "I" -> 2
        _ -> 1
      end
  end
end
