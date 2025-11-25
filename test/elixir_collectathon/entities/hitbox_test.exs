defmodule ElixirCollectathon.Entities.HitboxTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Entities.Hitbox

  alias ElixirCollectathon.Entities.Hitbox

  describe "new/2 - square hitbox" do
    test "creates a square hitbox with position and side length" do
      hitbox = Hitbox.new({0, 0}, 40)

      assert hitbox == {0, 0, 40, 40}
    end

    test "creates a hitbox at different position" do
      hitbox = Hitbox.new({10, 20}, 40)

      assert hitbox == {10, 20, 50, 60}
    end

    test "creates hitboxes with different sizes" do
      hitbox_small = Hitbox.new({0, 0}, 32)
      hitbox_large = Hitbox.new({0, 0}, 48)

      assert hitbox_small == {0, 0, 32, 32}
      assert hitbox_large == {0, 0, 48, 48}
    end
  end

  describe "new/3 - rectangular hitbox" do
    test "creates a rectangular hitbox with width and height" do
      hitbox = Hitbox.new({0, 0}, 40, 50)

      assert hitbox == {0, 0, 40, 50}
    end

    test "creates a hitbox at different position" do
      hitbox = Hitbox.new({10, 20}, 40, 50)

      assert hitbox == {10, 20, 50, 70}
    end

    test "creates hitboxes with different dimensions" do
      hitbox_wide = Hitbox.new({0, 0}, 100, 50)
      hitbox_tall = Hitbox.new({0, 0}, 50, 100)

      assert hitbox_wide == {0, 0, 100, 50}
      assert hitbox_tall == {0, 0, 50, 100}
    end
  end
end
