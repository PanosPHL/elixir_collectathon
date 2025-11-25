defmodule ElixirCollectathon.Entities.SpawnerTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Entities.Spawner

  alias ElixirCollectathon.Entities.Spawner
  alias ElixirCollectathon.Games.Game

  describe "spawn_player/2" do
    test "spawns player 1 at top-left corner" do
      player = Spawner.spawn_player("Alice", 1)

      assert player.name == "Alice"
      assert player.player_num == 1
      assert player.position == {0, 0}
    end

    test "spawns player 2 at top-right corner" do
      player = Spawner.spawn_player("Bob", 2)

      assert player.name == "Bob"
      assert player.player_num == 2
      # Top-right: {map_x - player_size, 0} = {1024 - 40, 0} = {984, 0}
      assert player.position == {984, 0}
    end

    test "spawns player 3 at bottom-left corner" do
      player = Spawner.spawn_player("Charlie", 3)

      assert player.name == "Charlie"
      assert player.player_num == 3
      # Bottom-left: {0, map_y - player_size} = {0, 576 - 40} = {0, 536}
      assert player.position == {0, 536}
    end

    test "spawns player 4 at bottom-right corner" do
      player = Spawner.spawn_player("Dave", 4)

      assert player.name == "Dave"
      assert player.player_num == 4
      # Bottom-right: {map_x - player_size, map_y - player_size} = {984, 536}
      assert player.position == {984, 536}
    end

    test "spawned player has correct color" do
      player1 = Spawner.spawn_player("Alice", 1)
      player2 = Spawner.spawn_player("Bob", 2)
      player3 = Spawner.spawn_player("Charlie", 3)
      player4 = Spawner.spawn_player("Dave", 4)

      assert player1.color == "red"
      assert player2.color == "blue"
      assert player3.color == "yellow"
      assert player4.color == "green"
    end

    test "spawned player has correct hitbox" do
      player = Spawner.spawn_player("Alice", 1)

      assert player.hitbox == {0, 0, 40, 40}
    end
  end

  describe "spawn_letter/1" do
    test "spawns a letter with valid character" do
      game = Game.new("ABC123")
      letter = Spawner.spawn_letter(game.players)

      assert letter.char in ["E", "L", "I", "X", "R"]
    end

    test "spawned letter has valid position within map bounds" do
      game = Game.new("ABC123")
      letter = Spawner.spawn_letter(game.players)

      {x, y} = letter.position
      letter_size = 48
      padding = 24

      assert x >= padding
      assert x <= 1024 - letter_size - padding
      assert y >= padding
      assert y <= 576 - letter_size - padding
    end

    test "spawned letter has correct hitbox" do
      game = Game.new("ABC123")
      letter = Spawner.spawn_letter(game.players)

      {x, y} = letter.position
      assert letter.hitbox == {x, y, x + 48, y + 48}
    end

    test "spawned letter does not collide with players" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Spawner.spawn_player("Alice", 1))

      letter = Spawner.spawn_letter(game.players)

      # Manual collision check
      {ax1, ay1, ax2, ay2} = letter.hitbox
      {bx1, by1, bx2, by2} = game.players["Alice"].hitbox

      collides? = not (ax2 <= bx1 or ax1 >= bx2 or ay2 <= by1 or ay1 >= by2)

      refute collides?
    end

    test "spawned letter avoids all players" do
      game =
        Game.new("ABC123")
        |> Game.add_player(Spawner.spawn_player("Alice", 1))
        |> Game.add_player(Spawner.spawn_player("Bob", 2))
        |> Game.add_player(Spawner.spawn_player("Charlie", 3))
        |> Game.add_player(Spawner.spawn_player("Dave", 4))

      # Spawn multiple letters and verify none collide
      Enum.each(1..10, fn _ ->
        letter = Spawner.spawn_letter(game.players)

        Enum.each(game.players, fn {_name, player} ->
          {ax1, ay1, ax2, ay2} = letter.hitbox
          {bx1, by1, bx2, by2} = player.hitbox

          collides? = not (ax2 <= bx1 or ax1 >= bx2 or ay2 <= by1 or ay1 >= by2)

          refute collides?
        end)
      end)
    end
  end
end
