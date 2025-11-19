defmodule ElixirCollectathon.Players.PlayerTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Games.Game

  describe "new/2" do
    test "creates a new player with default position for player 1" do
      player = Player.new("Alice", 1)

      assert player.name == "Alice"
      assert player.color == "red"
      assert player.position == {0, 0}
      assert player.velocity == {0, 0}
      assert player.inventory == ""
    end

    test "creates a player with correct position for player 2" do
      {map_x, _map_y} = Game.get_map_size()
      player = Player.new("Bob", 2)

      assert player.name == "Bob"
      assert player.color == "blue"
      assert player.position == {map_x - 40, 0}
    end

    test "creates a player with correct position for player 3" do
      {_map_x, map_y} = Game.get_map_size()
      player = Player.new("Charlie", 3)

      assert player.name == "Charlie"
      assert player.color == "yellow"
      assert player.position == {0, map_y - 40}
    end

    test "creates a player with correct position for player 4" do
      {map_x, map_y} = Game.get_map_size()
      player = Player.new("Diana", 4)

      assert player.name == "Diana"
      assert player.color == "green"
      assert player.position == {map_x - 40, map_y - 40}
    end

    test "defaults to player 1 if no player_num provided" do
      player = Player.new("Alice")

      assert player.color == "red"
      assert player.position == {0, 0}
    end

    test "assigns correct colors for each player number" do
      assert Player.new("P1", 1).color == "red"
      assert Player.new("P2", 2).color == "blue"
      assert Player.new("P3", 3).color == "yellow"
      assert Player.new("P4", 4).color == "green"
    end
  end

  describe "set_velocity/2" do
    test "updates the player's velocity" do
      player = Player.new("Alice", 1)
      new_velocity = {1.0, -1.0}

      updated_player = Player.set_velocity(player, new_velocity)

      assert updated_player.velocity == new_velocity
      assert updated_player.position == player.position
      assert updated_player.name == player.name
    end

    test "preserves other player attributes when setting velocity" do
      player = Player.new("Alice", 1)
      updated_player = Player.set_velocity(player, {0.5, 0.5})

      assert updated_player.name == "Alice"
      assert updated_player.color == "red"
      assert updated_player.position == {0, 0}
    end
  end

  describe "set_position/2" do
    test "updates the player's position" do
      player = Player.new("Alice", 1)
      new_position = {100, 200}

      updated_player = Player.set_position(player, new_position)

      assert updated_player.position == new_position
      assert updated_player.velocity == player.velocity
      assert updated_player.name == player.name
    end

    test "preserves other player attributes when setting position" do
      player = Player.new("Alice", 1)
      updated_player = Player.set_position(player, {50, 75})

      assert updated_player.name == "Alice"
      assert updated_player.color == "red"
      assert updated_player.velocity == {0, 0}
    end
  end
end
