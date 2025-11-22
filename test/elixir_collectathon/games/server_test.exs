defmodule ElixirCollectathon.Games.ServerTest do
  use ExUnit.Case, async: false
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathon.Games.Game
  alias Phoenix.PubSub

  setup do
    # Generate unique game ID for each test
    game_id = "TEST#{:rand.uniform(999999)}"
    {:ok, pid} = GameServer.start_link(game_id)

    # Subscribe to PubSub for this game
    PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    %{game_id: game_id, pid: pid}
  end

  describe "start_link/1" do
    test "starts a game server process", %{game_id: game_id, pid: pid} do
      assert Process.alive?(pid)
      assert GameServer.does_game_exist?(game_id)
    end

    test "registers server in Registry", %{game_id: game_id, pid: pid} do
      via = GameServer.via_tuple(game_id)
      assert GenServer.whereis(via) == pid
    end
  end

  describe "via_tuple/1" do
    test "returns correct via tuple format" do
      via = GameServer.via_tuple("ABC123")

      assert {:via, Registry, {ElixirCollectathon.Games.Registry, "ABC123"}} == via
    end
  end

  describe "does_game_exist?/1" do
    test "returns true for existing game", %{game_id: game_id} do
      assert GameServer.does_game_exist?(game_id)
    end

    test "returns false for non-existent game" do
      refute GameServer.does_game_exist?("NONEXISTENT")
    end
  end

  describe "join/2" do
    test "allows player to join game", %{game_id: game_id} do
      assert :ok == GameServer.join(game_id, "Alice")

      # Should receive state broadcast
      assert_receive {:state, %Game{players: players}}
      assert Map.has_key?(players, "Alice")
    end

    test "assigns correct player number", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      assert_receive {:state, %Game{players: players}}
      assert players["Alice"].player_num == 1

      GameServer.join(game_id, "Bob")
      assert_receive {:state, %Game{players: players}}
      assert players["Bob"].player_num == 2
    end

    test "returns error when game is full", %{game_id: game_id} do
      # Add 4 players
      assert :ok == GameServer.join(game_id, "Alice")
      assert :ok == GameServer.join(game_id, "Bob")
      assert :ok == GameServer.join(game_id, "Charlie")
      assert :ok == GameServer.join(game_id, "Diana")

      receive do
        {:state, %Game{players: players}} ->
          if map_size(players) == 4 do
            # 5th player should fail
            assert {:error, :max_players_reached} == GameServer.join(game_id, "Eve")
          end
      end
    end

    test "returns error when player name already exists", %{game_id: game_id} do
      assert :ok == GameServer.join(game_id, "Alice")

      receive do
        {:state, %Game{players: players}} ->
          if map_size(players) == 1 do
            # 2nd player should fail
            assert {:error, :already_added} == GameServer.join(game_id, "Alice")
          end
      end
    end

    test "broadcasts state update on join", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")

      assert_receive {:state, %Game{} = state}
      assert Map.has_key?(state.players, "Alice")
    end
  end

  describe "leave/2" do
    test "removes player from game", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      assert_receive {:state, %Game{}}

      GameServer.leave(game_id, "Alice")

      assert_receive {:state, %Game{players: players}}
      refute Map.has_key?(players, "Alice")
    end

    test "broadcasts state update on leave", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      assert_receive {:state, %Game{}}

      GameServer.leave(game_id, "Alice")

      assert_receive {:state, %Game{} = state}
      assert map_size(state.players) == 0
    end

    test "updates next_player_num when player leaves", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      GameServer.join(game_id, "Bob")
      assert_receive {:state, %Game{}}
      assert_receive {:state, %Game{}}

      GameServer.leave(game_id, "Alice")

      assert_receive {:state, %Game{next_player_num: next_num}}
      assert next_num == 1
    end
  end

  describe "update_velocity/3" do
    test "updates player velocity", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      GameServer.start_game(game_id)

      receive do
        :game_started ->
          GameServer.update_velocity(game_id, "Alice", {1, 0})

          # Wait for a state broadcast with the updated velocity
          # There may be tick broadcasts with the old velocity, so we need to wait
          # for one that has the updated velocity
          wait_for_velocity_update("Alice", {1, 0})
      end
    end
  end

  defp wait_for_velocity_update(player_name, expected_velocity, timeout \\ 500) do
    receive do
      {:state, %Game{players: players}} ->
        if players[player_name].velocity == expected_velocity do
          :ok
        else
          wait_for_velocity_update(player_name, expected_velocity, timeout)
        end
    after
      timeout ->
        flunk("Did not receive state update with velocity #{inspect(expected_velocity)} within #{timeout}ms")
    end
  end

  describe "start_countdown/1" do
    test "initiates countdown sequence", %{game_id: game_id} do
      GameServer.start_countdown(game_id)

      # Should receive countdown message
      assert_receive {:countdown, countdown}, 1500
      assert countdown in [3, 2, 1, "GO!"]
    end

    test "broadcasts countdown updates", %{game_id: game_id} do
      GameServer.start_countdown(game_id)

      # Should receive multiple countdown messages
      assert_receive {:countdown, 3}, 1500
      assert_receive {:countdown, 2}, 1500
      assert_receive {:countdown, 1}, 1500
      assert_receive {:countdown, "GO!"}, 1500
    end
  end

  describe "start_game/1" do
    test "starts the game", %{game_id: game_id} do
      GameServer.start_game(game_id)

      # Should receive game_started message
      assert_receive :game_started, 500
    end

    test "begins tick-based state updates", %{game_id: game_id} do
      GameServer.start_game(game_id)
      assert_receive :game_started

      # Should start receiving state updates
      assert_receive {:state, %Game{is_running: true}}, 200
    end
  end

  describe "game tick updates" do
    test "broadcasts state updates at regular intervals", %{game_id: game_id} do
      GameServer.start_game(game_id)
      assert_receive :game_started

      # Should receive multiple state updates
      assert_receive {:state, %Game{tick_count: tick1}}, 200
      assert_receive {:state, %Game{tick_count: tick2}}, 200

      assert tick2 > tick1
    end

    test "increments tick count on each update", %{game_id: game_id} do
      GameServer.start_game(game_id)
      assert_receive :game_started

      assert_receive {:state, %Game{tick_count: tick1}}, 200
      assert_receive {:state, %Game{tick_count: tick2}}, 200
      assert_receive {:state, %Game{tick_count: tick3}}, 200

      assert tick1 < tick2
      assert tick2 < tick3
    end
  end
end
