defmodule ElixirCollectathon.Players.InventoryManagerTest do
  use ExUnit.Case, async: true

  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Letters.Letter
  alias ElixirCollectathon.Players.InventoryManager

  test "adds a collected letter when player doesn't have max" do
    p1 = Player.new("Alice", 1, {0, 0})
    p2 = Player.new("Bob", 2, {0, 0})

    players = %{"Alice" => p1, "Bob" => p2}
    game = Game.new("g") |> Game.set_players(players)
    game = %{game | current_letter: Letter.new("E")}

    updated = InventoryManager.handle_collected_letter(game, p1)

    assert updated.players["Alice"].inventory == ["E", nil, nil, nil, nil, nil]
    assert updated.current_letter == nil
  end

  test "collector already has max and no other player has the letter (no-op)" do
    p1 = Player.new("Alice", 1, {0, 0})
    # set Alice to already have two I's (max for I)
    p1 = %Player{p1 | inventory: [nil, nil, "I", nil, "I", nil]}

    p2 = Player.new("Bob", 2, {0, 0})

    players = %{"Alice" => p1, "Bob" => p2}
    game = Game.new("g") |> Game.set_players(players)
    game = %{game | current_letter: Letter.new("I")}

    updated = InventoryManager.handle_collected_letter(game, p1)

    # inventory unchanged for Alice, letter cleared from game
    assert updated.players["Alice"].inventory == [nil, nil, "I", nil, "I", nil]
    assert updated.current_letter == nil
  end

  test "collector has max and another player has the letter: remove from other player" do
    p1 = Player.new("Alice", 1, {0, 0})
    # Alice already has E (max for E is 1)
    p1 = %Player{p1 | inventory: ["E", nil, nil, nil, nil, nil]}

    p2 = Player.new("Bob", 2, {0, 0})
    # Bob also has E, which should be removed when Alice collects
    p2 = %Player{p2 | inventory: ["E", nil, nil, nil, nil, nil]}

    players = %{"Alice" => p1, "Bob" => p2}
    game = Game.new("g") |> Game.set_players(players)
    game = %{game | current_letter: Letter.new("E")}

    updated = InventoryManager.handle_collected_letter(game, p1)

    # Bob should have had his E removed
    assert updated.players["Bob"].inventory == [nil, nil, nil, nil, nil, nil]
    assert updated.current_letter == nil
  end
end
