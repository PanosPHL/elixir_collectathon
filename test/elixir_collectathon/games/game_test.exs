defmodule ElixirCollectathon.Games.GameTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Games.Game

  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Letters.Letter

  describe "new/1" do
    test "creates a new game with the given ID" do
      game = Game.new("ABC123")

      assert game.game_id == "ABC123"
    end

    test "initializes with no players" do
      game = Game.new("ABC123")

      assert game.players == %{}
    end

    test "initializes with tick count of 0" do
      game = Game.new("ABC123")

      assert game.tick_count == 0
    end

    test "initializes with is_running as false" do
      game = Game.new("ABC123")

      assert game.is_running == false
    end

    test "initializes with next_player_num of 1" do
      game = Game.new("ABC123")

      assert game.next_player_num == 1
    end

    test "initializes with countdown of 3" do
      game = Game.new("ABC123")

      assert game.countdown == 3
    end

    test "initializes with no current letter" do
      game = Game.new("ABC123")

      assert game.current_letter == nil
    end
  end

  describe "add_player/2" do
    test "adds a player to the game" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1, {0, 0})

      updated = Game.add_player(game, player)

      assert Map.has_key?(updated.players, "Alice")
    end

    test "increments next_player_num when adding a player" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1, {0, 0})

      updated = Game.add_player(game, player)

      assert updated.next_player_num == 2
    end

    test "adds multiple players" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1, {0, 0})
      player2 = Player.new("Bob", 2, {100, 0})

      updated = game |> Game.add_player(player1) |> Game.add_player(player2)

      assert map_size(updated.players) == 2
      assert Map.has_key?(updated.players, "Alice")
      assert Map.has_key?(updated.players, "Bob")
    end

    test "stores player in players map with name as key" do
      game = Game.new("ABC123")
      player = Player.new("Charlie", 3, {0, 100})

      updated = Game.add_player(game, player)

      assert updated.players["Charlie"] == player
    end
  end

  describe "remove_player/2" do
    test "removes a player from the game" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Player.new("Alice", 1, {0, 0}))
        |> Game.add_player(Player.new("Bob", 2, {100, 0}))

      updated = Game.remove_player(game, "Alice")

      refute Map.has_key?(updated.players, "Alice")
      assert Map.has_key?(updated.players, "Bob")
    end

    test "does nothing when removing non-existent player" do
      game = Game.new("ABC123") |> Game.add_player(Player.new("Alice", 1, {0, 0}))

      assert_raise KeyError, fn ->
        Game.remove_player(game, "NonExistent")
      end

      # original game remains unchanged when an error is raised
      assert Map.has_key?(game.players, "Alice")
      assert map_size(game.players) == 1
    end

    test "handles removing from empty player list" do
      game = Game.new("ABC123")

      assert_raise KeyError, fn ->
        Game.remove_player(game, "Alice")
      end

      # ensure original players map is still empty
      assert game.players == %{}
    end
  end

  describe "has_player?/2" do
    test "returns true when player exists" do
      game = Game.new("ABC123") |> Game.add_player(Player.new("Alice", 1, {0, 0}))

      assert Game.has_player?(game, "Alice")
    end

    test "returns false when player does not exist" do
      game = Game.new("ABC123")

      refute Game.has_player?(game, "Alice")
    end

    test "works with multiple players" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Player.new("Alice", 1, {0, 0}))
        |> Game.add_player(Player.new("Bob", 2, {100, 0}))

      assert Game.has_player?(game, "Alice")
      assert Game.has_player?(game, "Bob")
      refute Game.has_player?(game, "Charlie")
    end
  end

  describe "get_map_size/0" do
    test "returns map size as {1024, 576}" do
      assert Game.get_map_size() == {1024, 576}
    end
  end

  describe "set_players/2" do
    test "replaces all players in the game" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1, {0, 0})
      player2 = Player.new("Bob", 2, {100, 0})
      players = %{"Alice" => player1, "Bob" => player2}

      updated = Game.set_players(game, players)

      assert updated.players == players
    end

    test "overwrites existing players" do
      game = Game.new("ABC123") |> Game.add_player(Player.new("Eve", 4, {100, 100}))

      new_player = Player.new("Alice", 1, {0, 0})
      updated = Game.set_players(game, %{"Alice" => new_player})

      refute Map.has_key?(updated.players, "Eve")
      assert Map.has_key?(updated.players, "Alice")
    end
  end

  describe "countdown_to_start/1" do
    test "decrements countdown" do
      game = Game.new("ABC123")

      updated = Game.countdown_to_start(game)

      assert updated.countdown == 2
    end

    test "continues decrementing countdown" do
      game = Game.new("ABC123")

      updated = game |> Game.countdown_to_start() |> Game.countdown_to_start()

      assert updated.countdown == 1
    end

    test "sets countdown to GO when reaching 1" do
      game = Game.new("ABC123") |> Game.countdown_to_start() |> Game.countdown_to_start()

      updated = Game.countdown_to_start(game)

      assert updated.countdown == "GO!"
    end
  end

  describe "start/2" do
    test "sets is_running to true" do
      game = Game.new("ABC123")

      updated = Game.start(game)

      assert updated.is_running == true
    end

    test "sets the timer_ref to nil is none is provided" do
      game =
        Game.new("ABC123")
        |> Game.start()

      assert game.timer_ref == nil
    end

    test "sets the timer_ref if one is provided" do
      {:ok, timer_ref} = :timer.apply_after(1000, fn -> IO.puts("Hello world") end)

      game =
        Game.new("ABC123")
        |> Game.start(timer_ref)

      assert game.timer_ref == timer_ref

      :timer.cancel(timer_ref)
    end

    test "does not affect other game properties" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Player.new("Alice", 1, {0, 0}))

      updated = Game.start(game)

      assert updated.game_id == game.game_id
      assert map_size(updated.players) == 1
    end
  end

  describe "update_player_velocity/3" do
    test "updates player velocity" do
      game = Game.new("ABC123") |> Game.add_player(Player.new("Alice", 1, {0, 0}))

      updated = Game.update_player_velocity(game, "Alice", {1, 0})

      assert updated.players["Alice"].velocity == {1, 0}
    end

    test "does not affect other players" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Player.new("Alice", 1, {0, 0}))
        |> Game.add_player(Player.new("Bob", 2, {100, 0}))

      updated = Game.update_player_velocity(game, "Alice", {1, 0})

      assert updated.players["Alice"].velocity == {1, 0}
      assert updated.players["Bob"].velocity == {0, 0}
    end

    test "handles non-existent player gracefully" do
      game = Game.new("ABC123")

      assert_raise KeyError, fn ->
        Game.update_player_velocity(game, "NonExistent", {1, 0})
      end

      assert game.players == %{}
    end
  end

  describe "spawn_letter/1" do
    test "creates a letter in the current_letter field" do
      game = Game.new("ABC123")

      updated = Game.spawn_letter(game)

      assert updated.current_letter != nil
      assert updated.current_letter.__struct__ == Letter
    end

    test "letter has valid coordinates" do
      game = Game.new("ABC123")

      updated = Game.spawn_letter(game)

      {x, y} = updated.current_letter.position
      assert x >= 0 and x <= 1024
      assert y >= 0 and y <= 576
    end

    test "letter has valid character" do
      game = Game.new("ABC123")

      updated = Game.spawn_letter(game)

      assert updated.current_letter.char in ["E", "L", "I", "X", "R"]
    end
  end
end
