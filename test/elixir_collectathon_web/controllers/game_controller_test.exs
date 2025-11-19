defmodule ElixirCollectathonWeb.GameControllerTest do
  use ElixirCollectathonWeb.ConnCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathonWeb.Routes

  describe "join_game/2" do
    test "redirects to controller route with player name in session", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Alice"
        })

      assert redirected_to(conn) == Routes.controller(game_id)
      assert get_session(conn, :player) == "Alice"
    end

    test "stores player name in session", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Bob")

      conn =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Bob"
        })

      assert get_session(conn, :player) == "Bob"
    end

    test "handles different player names", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Charlie")

      conn =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Charlie"
        })

      assert get_session(conn, :player) == "Charlie"
      assert redirected_to(conn) == Routes.controller(game_id)
    end

    test "works with different game IDs", %{conn: conn} do
      {:ok, game_id1} = Supervisor.create_game()
      {:ok, game_id2} = Supervisor.create_game()

      Server.join(game_id1, "Player1")
      Server.join(game_id2, "Player2")

      conn1 =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id1,
          "player_name" => "Player1"
        })

      conn2 =
        build_conn()
        |> post(~p"/games/join/", %{
          "game_id" => game_id2,
          "player_name" => "Player2"
        })

      assert redirected_to(conn1) == Routes.controller(game_id1)
      assert redirected_to(conn2) == Routes.controller(game_id2)
      assert get_session(conn1, :player) == "Player1"
      assert get_session(conn2, :player) == "Player2"
    end

    # Note: Testing missing parameters would require error templates.
    # The controller uses pattern matching, so missing params would result
    # in a FunctionClauseError, which Phoenix handles with error pages.
    # These edge cases are better handled at the LiveView form validation level.

    test "handles empty player name", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      conn =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id,
          "player_name" => ""
        })

      # Should still redirect and store empty string in session
      assert redirected_to(conn) == Routes.controller(game_id)
      assert get_session(conn, :player) == ""
    end

    test "handles special characters in player name", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Player-123")

      conn =
        conn
        |> post(~p"/games/join/", %{
          "game_id" => game_id,
          "player_name" => "Player-123"
        })

      assert get_session(conn, :player) == "Player-123"
      assert redirected_to(conn) == Routes.controller(game_id)
    end
  end
end
