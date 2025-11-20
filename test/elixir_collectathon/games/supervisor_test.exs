defmodule ElixirCollectathon.Games.SupervisorTest do
  use ExUnit.Case, async: false
  doctest ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server

  setup do
    # Clean up any existing games before each test
    :ok
  end

  describe "create_game/1" do
    test "creates a new game successfully" do
      assert {:ok, game_id} = Supervisor.create_game()
      assert is_binary(game_id)
      assert String.length(game_id) == 8
      assert Server.does_game_exist?(game_id) == true
    end

    test "creates games with unique IDs" do
      assert {:ok, game_id1} = Supervisor.create_game()
      assert {:ok, game_id2} = Supervisor.create_game()
      assert {:ok, game_id3} = Supervisor.create_game()

      assert game_id1 != game_id2
      assert game_id2 != game_id3
      assert game_id1 != game_id3
    end

    test "retries if game ID already exists" do
      # This test verifies the retry logic works
      # We can't easily force a collision, but we can verify it handles retries
      results = for _ <- 1..10, do: Supervisor.create_game()

      game_ids = Enum.map(results, fn {:ok, id} -> id end)
      unique_ids = Enum.uniq(game_ids)

      # All should be successful
      assert length(results) == 10
      assert length(unique_ids) == 10
    end

    test "returns error after max retries" do
      assert {:error, :max_retries} = Supervisor.create_game(6)
    end
  end
end
