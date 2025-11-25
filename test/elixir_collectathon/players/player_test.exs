defmodule ElixirCollectathon.Players.PlayerTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Players.Player

  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Entities.Hitbox

  describe "new/3" do
    test "creates a player with name and player number" do
      player = Player.new("Alice", 1, {0, 0})

      assert player.name == "Alice"
      assert player.player_num == 1
      assert player.position == {0, 0}
    end

    test "assigns correct color for player 1" do
      player = Player.new("Alice", 1, {0, 0})
      assert player.color == "red"
    end

    test "assigns correct color for player 2" do
      player = Player.new("Bob", 2, {100, 0})
      assert player.color == "blue"
    end

    test "assigns correct color for player 3" do
      player = Player.new("Charlie", 3, {0, 100})
      assert player.color == "yellow"
    end

    test "assigns correct color for player 4" do
      player = Player.new("Dave", 4, {100, 100})
      assert player.color == "green"
    end

    test "creates hitbox at player position" do
      player = Player.new("Alice", 1, {10, 20})

      assert player.hitbox == Hitbox.new({10, 20}, 40)
    end

    test "initializes velocity to {0, 0}" do
      player = Player.new("Alice", 1, {0, 0})

      assert player.velocity == {0, 0}
    end

    test "initializes inventory with 6 nil values" do
      player = Player.new("Alice", 1, {0, 0})

      assert player.inventory == [nil, nil, nil, nil, nil, nil]
      assert length(player.inventory) == 6
    end
  end

  describe "set_velocity/2" do
    test "updates player velocity" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.set_velocity(player, {1, 0})

      assert updated.velocity == {1, 0}
    end

    test "can set negative velocity" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.set_velocity(player, {-1, -1})

      assert updated.velocity == {-1, -1}
    end

    test "can set float velocity" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.set_velocity(player, {0.5, 0.5})

      assert updated.velocity == {0.5, 0.5}
    end

    test "does not affect other player properties" do
      player = Player.new("Alice", 1, {10, 20})
      updated = Player.set_velocity(player, {1, 1})

      assert updated.name == player.name
      assert updated.position == player.position
      assert updated.color == player.color
    end
  end

  describe "add_collected_letter/2" do
    test "adds E to first inventory slot" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.add_collected_letter(player, "E")

      assert Enum.at(updated.inventory, 0) == "E"
    end

    test "adds L to second inventory slot" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.add_collected_letter(player, "L")

      assert Enum.at(updated.inventory, 1) == "L"
    end

    test "adds first I to third inventory slot" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.add_collected_letter(player, "I")

      assert Enum.at(updated.inventory, 2) == "I"
    end

    test "adds second I to fifth inventory slot" do
      updated =
        Player.new("Alice", 1, {0, 0})
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("I")

      assert Enum.at(updated.inventory, 2) == "I"
      assert Enum.at(updated.inventory, 4) == "I"
    end

    test "adds X to fourth inventory slot" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.add_collected_letter(player, "X")

      assert Enum.at(updated.inventory, 3) == "X"
    end

    test "adds R to sixth inventory slot" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.add_collected_letter(player, "R")

      assert Enum.at(updated.inventory, 5) == "R"
    end

    test "can add multiple letters in order" do
      player =
        Player.new("Alice", 1, {0, 0})
        |> Player.add_collected_letter("E")
        |> Player.add_collected_letter("L")
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("X")
        |> Player.add_collected_letter("I")
        |> Player.add_collected_letter("R")

      assert player.inventory == ["E", "L", "I", "X", "I", "R"]
    end
  end

  describe "set_position/2" do
    test "updates player position" do
      player = Player.new("Alice", 1, {10, 20})
      updated = Player.set_position(player, {30, 40})

      assert updated.position == {30, 40}
    end

    test "updates hitbox when position changes" do
      player = Player.new("Alice", 1, {0, 0})
      updated = Player.set_position(player, {50, 50})

      assert updated.hitbox == Hitbox.new({50, 50}, 40)
    end

    test "does not affect other player properties" do
      player = Player.new("Alice", 1, {10, 20})
      updated = Player.set_position(player, {30, 40})

      assert updated.name == player.name
      assert updated.color == player.color
    end
  end

  describe "get_player_size/0" do
    test "returns 40" do
      assert Player.get_player_size() == 40
    end
  end
end
