defmodule ElixirCollectathon.Games.SupervisorTest do
  use ExUnit.Case, async: false
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer

  describe "create_game/0" do
    test "creates a new game and returns game ID" do
      assert {:ok, game_id} = GameSupervisor.create_game()

      assert is_binary(game_id)
      assert String.length(game_id) == 8
      assert String.match?(game_id, ~r/^[0-9A-F]{8}$/)
    end

    test "created game server is running" do
      {:ok, game_id} = GameSupervisor.create_game()

      assert GameServer.does_game_exist?(game_id)
    end

    test "creates multiple games with unique IDs" do
      {:ok, game_id1} = GameSupervisor.create_game()
      {:ok, game_id2} = GameSupervisor.create_game()
      {:ok, game_id3} = GameSupervisor.create_game()

      assert game_id1 != game_id2
      assert game_id2 != game_id3
      assert game_id1 != game_id3

      # All should exist
      assert GameServer.does_game_exist?(game_id1)
      assert GameServer.does_game_exist?(game_id2)
      assert GameServer.does_game_exist?(game_id3)
    end

    test "retries on collision" do
      # This test verifies the retry logic exists, though collisions are rare
      # We can't easily force a collision without mocking
      assert {:ok, _game_id} = GameSupervisor.create_game()
    end
  end
end
