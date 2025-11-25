defmodule ElixirCollectathon.Games.CollisionDetectorTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Games.CollisionDetector

  alias ElixirCollectathon.Games.CollisionDetector
  alias ElixirCollectathon.Entities.Hitbox

  describe "collides?/2" do
    test "detects collision when hitboxes overlap" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({20, 20}, 40)

      assert CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects collision when hitboxes partially overlap on x-axis" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({30, 0}, 40)

      assert CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects collision when hitboxes partially overlap on y-axis" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({0, 30}, 40)

      assert CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects collision when one hitbox is inside another" do
      hitbox1 = Hitbox.new({0, 0}, 100)
      hitbox2 = Hitbox.new({20, 20}, 40)

      assert CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects no collision when hitboxes are separated horizontally" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({50, 0}, 40)

      refute CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects no collision when hitboxes are separated vertically" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({0, 50}, 40)

      refute CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects no collision when hitboxes are diagonal" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({50, 50}, 40)

      refute CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects collision at edge (touching)" do
      hitbox1 = Hitbox.new({0, 0}, 40)
      hitbox2 = Hitbox.new({40, 0}, 40)

      refute CollisionDetector.collides?(hitbox1, hitbox2)
    end

    test "detects collision with rectangular hitboxes" do
      hitbox1 = Hitbox.new({0, 0}, 100, 50)
      hitbox2 = Hitbox.new({80, 30}, 40, 50)

      assert CollisionDetector.collides?(hitbox1, hitbox2)
    end
  end

  describe "collides_with_any?/3" do
    test "detects collision with one obstacle" do
      player_hitbox = Hitbox.new({10, 10}, 40)
      obstacle = {"Bob", Hitbox.new({40, 40}, 40)}
      occupied = [obstacle]

      assert CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "detects no collision with one obstacle when separated" do
      player_hitbox = Hitbox.new({0, 0}, 40)
      obstacle = {"Bob", Hitbox.new({100, 100}, 40)}
      occupied = [obstacle]

      refute CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "detects collision among multiple obstacles" do
      player_hitbox = Hitbox.new({10, 10}, 40)
      obstacle1 = {"Bob", Hitbox.new({200, 200}, 40)}
      obstacle2 = {"Charlie", Hitbox.new({30, 30}, 40)}
      occupied = [obstacle1, obstacle2]

      assert CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "ignores collision with self" do
      player_hitbox = Hitbox.new({0, 0}, 40)
      self_obstacle = {"Alice", Hitbox.new({10, 10}, 40)}
      occupied = [self_obstacle]

      refute CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "checks all obstacles in list" do
      player_hitbox = Hitbox.new({0, 0}, 40)
      obstacle1 = {"Bob", Hitbox.new({200, 200}, 40)}
      obstacle2 = {"Charlie", Hitbox.new({300, 300}, 40)}
      obstacle3 = {"Dave", Hitbox.new({400, 400}, 40)}
      occupied = [obstacle1, obstacle2, obstacle3]

      refute CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "returns true when empty occupied list" do
      player_hitbox = Hitbox.new({0, 0}, 40)
      occupied = []

      refute CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end

    test "handles multiple players with mixed collisions" do
      player_hitbox = Hitbox.new({25, 25}, 40)
      obstacle1 = {"Bob", Hitbox.new({0, 0}, 40)}
      obstacle2 = {"Charlie", Hitbox.new({100, 100}, 40)}
      occupied = [obstacle1, obstacle2]

      assert CollisionDetector.collides_with_any?(player_hitbox, occupied, "Alice")
    end
  end
end
