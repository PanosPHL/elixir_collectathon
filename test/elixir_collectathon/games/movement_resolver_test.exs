defmodule ElixirCollectathon.Games.MovementResolverTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Games.MovementResolver

  alias ElixirCollectathon.Games.MovementResolver
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathon.Entities.Hitbox

  describe "resolve/4" do
    test "moves player to target when no collision" do
      player = Player.new("Alice", 1, {0, 0})
      target = {10, 20}
      occupied = []
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_pos == {10, 20}
    end

    test "returns final hitbox matching final position" do
      player = Player.new("Alice", 1, {0, 0})
      target = {10, 20}
      occupied = []
      size = 40

      {final_pos, final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_hitbox == Hitbox.new(final_pos, size)
    end

    test "blocks movement on x-axis when collision" do
      size = Player.get_player_size()
      player = Player.new("Alice", 1, {0, 0})
      # Bob at {45, 0} so x-range is {45, 85}. Alice trying x=45 will collide
      bob_hitbox = Hitbox.new({45, 0}, size)
      occupied = [{"Bob", bob_hitbox}]
      target = {45, 20}

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      # x movement to 45 collides with Bob, so x stays at 0
      # y movement to 20 is free, so y moves to 20
      assert final_pos == {0, 20}
    end

    test "blocks movement on y-axis when collision on target y" do
      size = Player.get_player_size()
      player = Player.new("Alice", 1, {20, 45})
      bob_hitbox = Hitbox.new({0, 0}, size)
      occupied = [{"Bob", bob_hitbox}]
      target = {30, 20}

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      # x movement to {10, 0} collides with Bob, so both axes are blocked.
      assert final_pos == {30, 45}
    end

    test "allows diagonal sliding when blocked on one axis" do
      player = Player.new("Alice", 1, {0, 0})
      bob_hitbox = Hitbox.new({10, 50}, 40)
      occupied = [{"Bob", bob_hitbox}]
      target = {10, 10}
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      # Bob is at {10, 50, 50, 90} (no overlap with y=0-40 range)
      # Check x-axis at {10, 0}: hitbox {10, 0, 50, 40}. Bob at {10, 50, 50, 90}
      # x's overlap but y's don't (40 <= 50? YES), so no collision. x = 10
      # Check y-axis at {10, 10}: hitbox {10, 10, 50, 50}. Bob at {10, 50, 50, 90}
      # y's don't overlap (50 <= 50? YES edge case), so no collision. y = 10
      assert final_pos == {10, 10}
    end

    test "blocks movement on y-axis when collision" do
      player = Player.new("Alice", 1, {0, 0})
      bob_hitbox = Hitbox.new({0, 10}, 40)
      occupied = [{"Bob", bob_hitbox}]
      target = {10, 10}
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      # x movement to {10, 0} actually collides with Bob (overlapping area),
      # so both axes are blocked and the player remains at {0, 0}.
      assert final_pos == {0, 0}
    end

    test "handles collision with multiple obstacles" do
      player = Player.new("Alice", 1, {0, 0})
      bob_hitbox = Hitbox.new({10, 0}, 40)
      charlie_hitbox = Hitbox.new({0, 10}, 40)
      occupied = [{"Bob", bob_hitbox}, {"Charlie", charlie_hitbox}]
      target = {10, 10}
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_pos == {0, 0}
    end

    test "ignores obstacles named after the player" do
      player = Player.new("Alice", 1, {0, 0})
      alice_hitbox = Hitbox.new({10, 10}, 40)
      occupied = [{"Alice", alice_hitbox}]
      target = {10, 10}
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_pos == {10, 10}
    end

    test "allows movement to same position" do
      player = Player.new("Alice", 1, {10, 10})
      target = {10, 10}
      occupied = []
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_pos == {10, 10}
    end

    test "handles large movements" do
      player = Player.new("Alice", 1, {0, 0})
      target = {1000, 1000}
      occupied = []
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      assert final_pos == {1000, 1000}
    end

    test "checks x-axis before y-axis for collision" do
      player = Player.new("Alice", 1, {0, 0})
      bob_hitbox = Hitbox.new({10, 30}, 40)
      occupied = [{"Bob", bob_hitbox}]
      target = {10, 20}
      size = 40

      {final_pos, _final_hitbox} = MovementResolver.resolve(player, target, occupied, size)

      # In this scenario x-check at {10,0} overlaps Bob vertically (30-70 vs 0-40 overlap),
      # so x is blocked and subsequently y at {0,20} also collides — player stays at {0,0}.
      assert final_pos == {0, 0}
    end
  end
end
