defmodule ElixirCollectathon.Games.ServerTest do
  use ExUnit.Case

  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer

  setup do
    {:ok, game_id} = GameSupervisor.create_game()
    Phoenix.PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    %{game_id: game_id}
  end

  describe "via_tuple/1" do
    test "returns correct via tuple format" do
      via = GameServer.via_tuple("ABC123")

      assert via == {:via, Registry, {ElixirCollectathon.Games.Registry, "ABC123"}}
    end
  end

  describe "does_game_exist?/1" do
    test "returns true when game exists", %{game_id: game_id} do
      assert GameServer.does_game_exist?(game_id)
    end

    test "returns false when game does not exist" do
      refute GameServer.does_game_exist?("NONEXISTENT")
    end
  end

  describe "join/2" do
    test "allows player to join an empty game", %{game_id: game_id} do
      result = GameServer.join(game_id, "Alice")

      assert result == :ok
    end

    test "allows up to 4 players to join", %{game_id: game_id} do
      names = ["Alice", "Bob", "Charlie", "Dave"]

      Enum.each(names, fn name ->
        assert GameServer.join(game_id, name) == :ok
      end)
    end

    test "prevents 5th player from joining", %{game_id: game_id} do
      ["Alice", "Bob", "Charlie", "Dave"]
      |> Enum.each(&GameServer.join(game_id, &1))

      result = GameServer.join(game_id, "Eve")

      assert result == {:error, :max_players_reached}
    end

    test "prevents duplicate player names", %{game_id: game_id} do
      :ok = GameServer.join(game_id, "Alice")

      result = GameServer.join(game_id, "Alice")

      assert result == {:error, :already_added}
    end

    test "broadcasts game state when player joins", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")

      assert_receive {:state, _game_state}
    end
  end

  describe "leave/2" do
    test "allows player to leave game", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")

      result = GameServer.leave(game_id, "Alice")

      assert result == :ok
    end

    test "broadcasts when player leaves", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      assert_receive {:state, _}

      GameServer.leave(game_id, "Alice")

      assert_receive {:state, game_state}
      assert map_size(game_state.players) == 0
    end

    test "allows another player to join after one leaves", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      GameServer.leave(game_id, "Alice")

      result = GameServer.join(game_id, "Bob")

      assert result == :ok
    end
  end

  describe "update_velocity/3" do
    test "updates player velocity", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      assert_receive {:state, _}

      GameServer.start_game(game_id)
      GameServer.update_velocity(game_id, "Alice", {1, 0})

      assert_receive {:state, game_state}
      assert game_state.players["Alice"].velocity == {1, 0}
    end
  end

  describe "start_countdown/1" do
    test "starts the countdown", %{game_id: game_id} do
      GameServer.start_countdown(game_id)

      assert_receive {:countdown, 3}
    end
  end

  describe "start_game/1" do
    test "starts the game", %{game_id: game_id} do
      GameServer.start_countdown(game_id)
      assert_receive {:countdown, 3}

      GameServer.start_game(game_id)

      assert_receive :game_started
    end

    test "sets is_running to true", %{game_id: game_id} do
      GameServer.start_game(game_id)

      assert_receive {:state, game_state}
      assert game_state.is_running == true
    end
  end

  describe "game shutdown on winner" do
    test "game server continues running when game is active", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      GameServer.join(game_id, "Bob")
      GameServer.start_game(game_id)

      assert_receive {:state, _game_state}

      receive do
        {:state, _game_state} ->
          via = GameServer.via_tuple(game_id)
          pid = GenServer.whereis(via)

          assert is_pid(pid)
          assert Process.alive?(pid)
      after
        1000 ->
          flunk("Did not receive state updates")
      end
    end

    test "game server stops after shutdown message is sent", %{game_id: game_id} do
      GameServer.join(game_id, "Alice")
      GameServer.join(game_id, "Bob")

      via = GameServer.via_tuple(game_id)
      pid = GenServer.whereis(via)

      send(pid, :shutdown_game)

      assert is_nil(GenServer.whereis(via))
    end
  end
end
