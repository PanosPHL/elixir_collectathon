defmodule ElixirCollectathonWeb.GameControllerTest do
  use ElixirCollectathonWeb.ConnCase, async: true
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer

  describe "join_game/2" do
    test "stores game_id in session", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      conn = conn
        |> init_test_session(%{})
        |> post("/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Alice"
        })

      assert get_session(conn, :game_id) == game_id

      # Clean up
      pid = GenServer.whereis(GameServer.via_tuple(game_id))
      if pid && Process.alive?(pid) do
        GenServer.stop(pid, :normal, 100)
      end
    end

    test "stores player_name in session", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      conn = conn
        |> init_test_session(%{})
        |> post("/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Alice"
        })

      assert get_session(conn, :player) == "Alice"

      # Clean up
      pid = GenServer.whereis(GameServer.via_tuple(game_id))
      if pid && Process.alive?(pid) do
        GenServer.stop(pid, :normal, 100)
      end
    end

    test "redirects to controller view", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      conn = conn
        |> init_test_session(%{})
        |> post("/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Alice"
        })

      assert redirected_to(conn) == "/controller/#{game_id}"

      # Clean up
      pid = GenServer.whereis(GameServer.via_tuple(game_id))
      if pid && Process.alive?(pid) do
        GenServer.stop(pid, :normal, 100)
      end
    end
  end
end
