defmodule ElixirCollectathon.Games.GameTest do
  use ExUnit.Case, async: true
  doctest ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player

  describe "new/1" do
    test "creates a new game with the given game_id" do
      game_id = "TEST123"
      game = Game.new(game_id)

      assert game.game_id == game_id
      assert game.tick_count == 0
      assert game.is_running == true
      assert game.players == %{}
      assert game.next_player_num == 1
    end
  end

  describe "add_player/2" do
    test "adds a player to the game" do
      game = Game.new("TEST123")
      player = Player.new("Alice", 1)

      updated_game = Game.add_player(game, player)

      assert Map.has_key?(updated_game.players, "Alice")
      assert updated_game.players["Alice"] == player
      assert updated_game.next_player_num == 2
    end

    test "increments next_player_num when adding a player" do
      game = Game.new("TEST123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)

      game =
        game
        |> Game.add_player(player1)
        |> Game.add_player(player2)

      assert game.next_player_num == 3
    end

    test "can add multiple players" do
      game = Game.new("TEST123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)
      player3 = Player.new("Charlie", 3)

      game =
        game
        |> Game.add_player(player1)
        |> Game.add_player(player2)
        |> Game.add_player(player3)

      assert map_size(game.players) == 3
      assert Map.has_key?(game.players, "Alice")
      assert Map.has_key?(game.players, "Bob")
      assert Map.has_key?(game.players, "Charlie")
    end
  end

  describe "get_map_size/0" do
    test "returns the map size tuple" do
      assert Game.get_map_size() == {1024, 576}
    end
  end

  describe "set_players/2" do
    test "replaces all players in the game" do
      game = Game.new("TEST123")
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)

      game = Game.add_player(game, player1)
      new_players = %{"Bob" => player2, "Charlie" => Player.new("Charlie", 3)}

      updated_game = Game.set_players(game, new_players)

      assert updated_game.players == new_players
      assert map_size(updated_game.players) == 2
      refute Map.has_key?(updated_game.players, "Alice")
    end
  end
end
