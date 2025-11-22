defmodule ElixirCollectathon.Games.GameTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Letters
  alias ElixirCollectathon.Letters.Letter

  describe "new/1" do
    test "creates a new game with given game ID" do
      game = Game.new("ABC123")

      assert game.game_id == "ABC123"
    end

    test "initializes with zero tick count" do
      game = Game.new("ABC123")

      assert game.tick_count == 0
    end

    test "initializes as not running" do
      game = Game.new("ABC123")

      assert game.is_running == false
    end

    test "initializes with empty players map" do
      game = Game.new("ABC123")

      assert game.players == %{}
    end

    test "initializes with next_player_num as 1" do
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
      player = Player.new("Alice", 1)
      updated = Game.add_player(game, player)

      assert Map.has_key?(updated.players, "Alice")
      assert updated.players["Alice"] == player
    end

    test "increments next_player_num" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)
      updated = Game.add_player(game, player)

      assert updated.next_player_num == 2
    end

    test "can add multiple players" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)

      updated = game
        |> Game.add_player(player1)
        |> Game.add_player(player2)

      assert map_size(updated.players) == 2
      assert Map.has_key?(updated.players, "Alice")
      assert Map.has_key?(updated.players, "Bob")
      assert updated.next_player_num == 3
    end
  end

  describe "remove_player/2" do
    test "removes a player from the game" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)

      updated = game
        |> Game.add_player(player)
        |> Game.remove_player("Alice")

      refute Map.has_key?(updated.players, "Alice")
    end

    test "updates next_player_num to removed player's number" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)

      updated = game
        |> Game.add_player(player1)
        |> Game.add_player(player2)
        |> Game.remove_player("Alice")

      assert updated.next_player_num == 1
    end

    test "preserves other players when removing one" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)

      updated = game
        |> Game.add_player(player1)
        |> Game.add_player(player2)
        |> Game.remove_player("Alice")

      assert Map.has_key?(updated.players, "Bob")
      assert map_size(updated.players) == 1
    end
  end

  describe "get_map_size/0" do
    test "returns map size as tuple" do
      assert Game.get_map_size() == {1024, 576}
    end
  end

  describe "set_players/2" do
    test "sets the players map" do
      game = Game.new("ABC123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)
      players = %{"Alice" => player1, "Bob" => player2}

      updated = Game.set_players(game, players)

      assert updated.players == players
      assert map_size(updated.players) == 2
    end
  end

  describe "has_player?/2" do
    test "returns true when player exists" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)
      updated = Game.add_player(game, player)

      assert Game.has_player?(updated, "Alice")
    end

    test "returns false when player does not exist" do
      game = Game.new("ABC123")

      refute Game.has_player?(game, "Alice")
    end
  end

  describe "countdown_to_start/1" do
    test "decrements countdown from 3 to 2" do
      game = Game.new("ABC123")
      updated = Game.countdown_to_start(game)

      assert updated.countdown == 2
    end

    test "decrements countdown from 2 to 1" do
      game = %{Game.new("ABC123") | countdown: 2}
      updated = Game.countdown_to_start(game)

      assert updated.countdown == 1
    end

    test "changes countdown to GO! when at 1" do
      game = %{Game.new("ABC123") | countdown: 1}
      updated = Game.countdown_to_start(game)

      assert updated.countdown == "GO!"
    end

    test "countdown sequence works correctly" do
      game = Game.new("ABC123")

      game = game
        |> Game.countdown_to_start()
        |> Game.countdown_to_start()
        |> Game.countdown_to_start()

      assert game.countdown == "GO!"
    end
  end

  describe "start/1" do
    test "sets is_running to true" do
      game = Game.new("ABC123")
      updated = Game.start(game)

      assert updated.is_running == true
    end

    test "spawns a letter" do
      game = Game.new("ABC123")
      updated = Game.start(game)

      assert updated.current_letter != nil
      assert is_struct(updated.current_letter, Letter)
    end
  end

  describe "update_player_velocity/3" do
    test "updates player velocity in the game" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)

      game = Game.add_player(game, player)
      updated = Game.update_player_velocity(game, "Alice", {1, 0})

      assert updated.players["Alice"].velocity == {1, 0}
    end

    test "preserves other player attributes" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)

      game = Game.add_player(game, player)
      updated = Game.update_player_velocity(game, "Alice", {0.5, -0.5})

      assert updated.players["Alice"].name == "Alice"
      assert updated.players["Alice"].position == player.position
      assert updated.players["Alice"].color == player.color
    end
  end

  describe "update_game_state/1" do
    test "increments tick count" do
      game = Game.new("ABC123")
      updated = Game.update_game_state(game)

      assert updated.tick_count == 1
    end

    test "increments tick count multiple times" do
      game = Game.new("ABC123")

      updated = game
        |> Game.update_game_state()
        |> Game.update_game_state()
        |> Game.update_game_state()

      assert updated.tick_count == 3
    end

    test "updates player positions based on velocity" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)

      updated = game
        |> Game.add_player(player)
        |> Game.update_player_velocity("Alice", {1, 0})
        |> Game.update_game_state()

      # Player should have moved (velocity * movement_speed = 1 * 15 = 15 pixels)
      assert updated.players["Alice"].position != {0, 0}
    end

    test "clamps player position to map boundaries" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)
      {map_x, map_y} = Game.get_map_size()

      # Set player at edge with velocity going out of bounds
      game = game
        |> Game.add_player(player)
        |> Game.set_players(%{"Alice" => %{player | position: {map_x - 40, map_y - 40}}})
        |> Game.update_player_velocity("Alice", {1, 1})
        |> Game.update_game_state()

      {x, y} = game.players["Alice"].position
      player_size = Player.get_player_size()

      # Position should be clamped to map boundaries
      assert x <= map_x - player_size
      assert y <= map_y - player_size
    end
  end

  describe "spawn_letter/1" do
    test "spawns a letter in the game" do
      game = Game.new("ABC123")
      updated = Game.spawn_letter(game)

      assert updated.current_letter != nil
      assert is_struct(updated.current_letter, Letter)
    end

    test "spawned letter has a valid character" do
      game = Game.new("ABC123")
      updated = Game.spawn_letter(game)

      assert updated.current_letter.char in Letters.get_letters()
    end

    test "spawned letter has a position within map bounds" do
      game = Game.new("ABC123")
      updated = Game.spawn_letter(game)

      {x, y} = updated.current_letter.position
      {map_x, map_y} = Game.get_map_size()
      letter_size = Letter.get_letter_size()
      padding = Letter.get_padding()

      assert x >= padding
      assert x <= map_x - letter_size - padding
      assert y >= padding
      assert y <= map_y - letter_size - padding
    end

    test "spawned letter does not collide with existing players" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)

      game = Game.add_player(game, player)

      # Spawn multiple letters and verify none collide with player
      for _ <- 1..10 do
        updated = Game.spawn_letter(game)
        {lx, ly} = updated.current_letter.position
        {px, py} = player.position

        # Letters should not be at exact same position as player
        refute {lx, ly} == {px, py}
      end
    end
  end

  describe "letter collision detection" do
    test "awards letter to player on collision" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)
      letter = Letter.new("E", {50, 50})

      # Position player very close to letter
      player = %{player | position: {50, 50}}

      game = game
        |> Game.add_player(player)
        |> Map.put(:current_letter, letter)
        |> Game.update_game_state()

      # Letter should be collected
      assert game.current_letter == nil
      assert game.players["Alice"].inventory == ["E", nil, nil, nil, nil, nil]
    end

    test "does not award letter when no collision" do
      game = Game.new("ABC123")
      player = Player.new("Alice", 1)
      letter = Letter.new("E", {500, 500})

      game = game
        |> Game.add_player(player)
        |> Map.put(:current_letter, letter)
        |> Game.update_game_state()

      # Letter should still be there (no collision)
      assert game.current_letter != nil
      assert game.players["Alice"].inventory == [nil, nil, nil, nil, nil, nil]
    end
  end
end
