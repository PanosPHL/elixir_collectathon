defmodule ElixirCollectathon.Games.SupervisorTest do
  use ExUnit.Case

  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer

  describe "create_game/0" do
    test "creates a game and returns a game ID" do
      {:ok, game_id} = GameSupervisor.create_game()

      assert is_binary(game_id)
      assert String.length(game_id) == 8
    end

    test "created game has a running server" do
      {:ok, game_id} = GameSupervisor.create_game()

      assert GameServer.does_game_exist?(game_id)
    end

    test "multiple creates return different game IDs" do
      {:ok, game_id1} = GameSupervisor.create_game()
      {:ok, game_id2} = GameSupervisor.create_game()

      assert game_id1 != game_id2
    end

    test "created games are independent" do
      {:ok, game_id1} = GameSupervisor.create_game()
      {:ok, game_id2} = GameSupervisor.create_game()

      :ok = GameServer.join(game_id1, "Alice")

      assert GameServer.does_game_exist?(game_id1)
      assert GameServer.does_game_exist?(game_id2)
    end
  end
end
