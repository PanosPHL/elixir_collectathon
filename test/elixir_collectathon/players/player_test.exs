defmodule ElixirCollectathon.Players.PlayerTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Games.Game

  describe "new/2" do
    test "creates a player with name and player number" do
      player = Player.new("Alice", 1)

      assert player.name == "Alice"
      assert player.player_num == 1
    end

    test "assigns correct color based on player number" do
      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)
      player3 = Player.new("Charlie", 3)
      player4 = Player.new("Diana", 4)

      assert player1.color == "red"
      assert player2.color == "blue"
      assert player3.color == "yellow"
      assert player4.color == "green"
    end

    test "assigns correct starting position based on player number" do
      {map_x, map_y} = Game.get_map_size()
      player_size = Player.get_player_size()

      player1 = Player.new("Alice", 1)
      player2 = Player.new("Bob", 2)
      player3 = Player.new("Charlie", 3)
      player4 = Player.new("Diana", 4)

      assert player1.position == {0, 0}
      assert player2.position == {map_x - player_size, 0}
      assert player3.position == {0, map_y - player_size}
      assert player4.position == {map_x - player_size, map_y - player_size}
    end

    test "initializes with zero velocity" do
      player = Player.new("Alice", 1)

      assert player.velocity == {0, 0}
    end

    test "initializes with empty inventory" do
      player = Player.new("Alice", 1)

      assert player.inventory == [nil, nil, nil, nil, nil, nil]
    end

    test "uses default player number 1 when not specified" do
      player = Player.new("Alice")

      assert player.player_num == 1
      assert player.color == "red"
      assert player.position == {0, 0}
    end
  end

  describe "set_velocity/2" do
    test "updates player velocity" do
      player = Player.new("Alice", 1)
      updated = Player.set_velocity(player, {1, 0})

      assert updated.velocity == {1, 0}
    end

    test "can set negative velocities" do
      player = Player.new("Alice", 1)
      updated = Player.set_velocity(player, {-1, -1})

      assert updated.velocity == {-1, -1}
    end

    test "preserves other player attributes" do
      player = Player.new("Alice", 1)
      updated = Player.set_velocity(player, {0.5, 0.5})

      assert updated.name == player.name
      assert updated.color == player.color
      assert updated.position == player.position
      assert updated.player_num == player.player_num
    end
  end

  describe "set_position/2" do
    test "updates player position" do
      player = Player.new("Alice", 1)
      updated = Player.set_position(player, {100, 200})

      assert updated.position == {100, 200}
    end

    test "preserves other player attributes" do
      player = Player.new("Alice", 1)
      updated = Player.set_position(player, {500, 300})

      assert updated.name == player.name
      assert updated.color == player.color
      assert updated.velocity == player.velocity
      assert updated.player_num == player.player_num
    end
  end

  describe "add_collected_letter/2" do
    test "adds E to first position" do
      player = Player.new("Alice", 1)
      updated = Player.add_collected_letter(player, "E")

      assert updated.inventory == ["E", nil, nil, nil, nil, nil]
    end

    test "adds L to second position" do
      player = Player.new("Alice", 1)
      updated = Player.add_collected_letter(player, "L")

      assert updated.inventory == [nil, "L", nil, nil, nil, nil]
    end

    test "adds first I to third position" do
      player = Player.new("Alice", 1)
      updated = Player.add_collected_letter(player, "I")

      assert updated.inventory == [nil, nil, "I", nil, nil, nil]
    end

    test "adds second I to fifth position when third is occupied" do
      player = Player.new("Alice", 1)
      updated = player
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("I")

      assert updated.inventory == [nil, nil, "I", nil, "I", nil]
    end

    test "adds X to fourth position" do
      player = Player.new("Alice", 1)
      updated = Player.add_collected_letter(player, "X")

      assert updated.inventory == [nil, nil, nil, "X", nil, nil]
    end

    test "adds R to sixth position" do
      player = Player.new("Alice", 1)
      updated = Player.add_collected_letter(player, "R")

      assert updated.inventory == [nil, nil, nil, nil, nil, "R"]
    end

    test "can collect all letters to spell ELIXIR" do
      player = Player.new("Alice", 1)

      updated = player
        |> Player.add_collected_letter("E")
        |> Player.add_collected_letter("L")
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("X")
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("R")

      assert updated.inventory == ["E", "L", "I", "X", "I", "R"]
    end
  end

  describe "get_player_size/0" do
    test "returns the player size constant" do
      assert Player.get_player_size() == 40
    end

    test "player size is a positive integer" do
      size = Player.get_player_size()

      assert is_integer(size)
      assert size > 0
    end
  end
end
