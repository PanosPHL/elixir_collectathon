defmodule ElixirCollectathon.Games.ServerTest do
  use ExUnit.Case, async: false
  doctest ElixirCollectathon.Games.Server
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathon.Games.Game

  setup do
    game_id = "TEST#{:rand.uniform(10000)}"
    {:ok, pid} = start_supervised({Server, game_id})
    {:ok, game_id: game_id, pid: pid}
  end

  describe "join/2" do
    test "allows a player to join a game", %{game_id: game_id} do
      assert Server.join(game_id, "Alice") == :ok
    end

    test "allows multiple players to join", %{game_id: game_id} do
      assert Server.join(game_id, "Alice") == :ok
      assert Server.join(game_id, "Bob") == :ok
      assert Server.join(game_id, "Charlie") == :ok
    end

    test "returns error when game has 4 players", %{game_id: game_id} do
      assert Server.join(game_id, "Player1") == :ok
      assert Server.join(game_id, "Player2") == :ok
      assert Server.join(game_id, "Player3") == :ok
      assert Server.join(game_id, "Player4") == :ok
      assert Server.join(game_id, "Player5") == {:error, :max_players_reached}
    end

    test "returns error when player name already exists", %{game_id: game_id} do
      assert Server.join(game_id, "Alice") == :ok
      assert Server.join(game_id, "Alice") == {:error, :already_added}
    end

    test "assigns correct player numbers", %{game_id: game_id} do
      Server.join(game_id, "Player1")
      Server.join(game_id, "Player2")
      Server.join(game_id, "Player3")
      Server.join(game_id, "Player4")

      state = :sys.get_state(Server.via_tuple(game_id))

      assert state.players["Player1"].color == "red"
      assert state.players["Player2"].color == "blue"
      assert state.players["Player3"].color == "yellow"
      assert state.players["Player4"].color == "green"
    end
  end

  describe "leave/2" do
    test "removes a player from the game", %{game_id: game_id} do
      Server.join(game_id, "Alice")
      Server.leave(game_id, "Alice")

      # Wait a bit for the cast to process
      Process.sleep(50)

      state = :sys.get_state(Server.via_tuple(game_id))
      refute Map.has_key?(state.players, "Alice")
    end

    test "frees up the player number", %{game_id: game_id} do
      Server.join(game_id, "Alice") # Player 1
      Server.join(game_id, "Bob")   # Player 2
      Server.leave(game_id, "Alice")

      Process.sleep(50)

      Server.join(game_id, "Charlie") # Should be Player 1

      state = :sys.get_state(Server.via_tuple(game_id))
      assert state.players["Charlie"].player_num == 1
    end
  end

  describe "update_velocity/3" do
    test "updates player velocity", %{game_id: game_id} do
      Server.join(game_id, "Alice")
      Server.update_velocity(game_id, "Alice", {1.0, 0.0})

      # Wait a bit for the cast to process
      Process.sleep(50)

      state = :sys.get_state(Server.via_tuple(game_id))
      assert state.players["Alice"].velocity == {1.0, 0.0}
    end

    test "updates velocity for multiple players", %{game_id: game_id} do
      Server.join(game_id, "Alice")
      Server.join(game_id, "Bob")

      Server.update_velocity(game_id, "Alice", {1.0, 0.0})
      Server.update_velocity(game_id, "Bob", {0.0, 1.0})

      Process.sleep(50)

      state = :sys.get_state(Server.via_tuple(game_id))
      assert state.players["Alice"].velocity == {1.0, 0.0}
      assert state.players["Bob"].velocity == {0.0, 1.0}
    end
  end

  describe "does_game_exist?/1" do
    test "returns true when game exists", %{game_id: game_id} do
      assert Server.does_game_exist?(game_id) == true
    end

    test "returns false when game does not exist" do
      assert Server.does_game_exist?("NONEXISTENT") == false
    end
  end

  describe "game tick updates" do
    test "increments tick_count on each tick", %{game_id: game_id} do
      initial_state = :sys.get_state(Server.via_tuple(game_id))
      initial_tick = initial_state.tick_count

      # Wait for a tick (33ms)
      Process.sleep(50)

      updated_state = :sys.get_state(Server.via_tuple(game_id))
      assert updated_state.tick_count > initial_tick
    end

    test "updates player position based on velocity", %{game_id: game_id} do
      Server.join(game_id, "Alice")
      Server.update_velocity(game_id, "Alice", {1.0, 0.0})

      Process.sleep(50)

      initial_state = :sys.get_state(Server.via_tuple(game_id))
      initial_position = initial_state.players["Alice"].position

      # Wait for another tick
      Process.sleep(50)

      updated_state = :sys.get_state(Server.via_tuple(game_id))
      updated_position = updated_state.players["Alice"].position

      assert updated_position != initial_position
      assert elem(updated_position, 0) > elem(initial_position, 0)
    end

    test "clamps player position to map boundaries", %{game_id: game_id} do
      Server.join(game_id, "Alice")
      {map_x, map_y} = Game.get_map_size()

      # Set velocity to move off the map
      Server.update_velocity(game_id, "Alice", {10.0, 10.0})

      # Wait for several ticks
      Process.sleep(200)

      state = :sys.get_state(Server.via_tuple(game_id))
      {x, y} = state.players["Alice"].position

      assert x >= 0
      assert x <= map_x - 40
      assert y >= 0
      assert y <= map_y - 40
    end

    test "broadcasts state updates via PubSub", %{game_id: game_id} do
      Phoenix.PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

      Server.join(game_id, "Alice")

      # Wait for a tick to broadcast
      assert_receive {:state, %Game{} = state}, 100
      assert Map.has_key?(state.players, "Alice")
    end
  end

  describe "via_tuple/1" do
    test "returns a via tuple for the registry" do
      game_id = "TEST123"
      via = Server.via_tuple(game_id)

      assert via == {:via, Registry, {ElixirCollectathon.Games.Registry, game_id}}
    end
  end
end
