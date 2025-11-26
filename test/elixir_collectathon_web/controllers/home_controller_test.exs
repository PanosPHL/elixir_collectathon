defmodule ElixirCollectathonWeb.HomeControllerTest do
  use ElixirCollectathonWeb.ConnCase, async: true
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer

  describe "index/2" do
    test "renders home page", %{conn: conn} do
      conn = get(conn, "/")

      assert html_response(conn, 200)
    end

    test "clears game_id from session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:game_id, "ABC123")
        |> get("/")

      assert get_session(conn, :game_id) == nil
    end

    test "clears player from session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:player, "Alice")
        |> get("/")

      assert get_session(conn, :player) == nil
    end

    test "handles form_view param", %{conn: conn} do
      conn = get(conn, "/?form_view=join-game")

      assert html_response(conn, 200)
    end

    test "handles form_view and game_id params", %{conn: conn} do
      conn = get(conn, "/?form_view=join-game&game_id=ABC123")

      assert html_response(conn, 200)
    end

    test "leaves current game when session exists", %{conn: conn} do
      # Create a game and join it
      {:ok, game_id} = GameSupervisor.create_game()
      GameServer.join(game_id, "Alice")

      # Set session
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:game_id, game_id)
        |> put_session(:player, "Alice")
        |> get("/")

      # Session should be cleared
      assert get_session(conn, :game_id) == nil
      assert get_session(conn, :player) == nil

      # Clean up
      pid = GenServer.whereis(GameServer.via_tuple(game_id))

      if pid && Process.alive?(pid) do
        GenServer.stop(pid, :normal, 100)
      end
    end
  end
end
