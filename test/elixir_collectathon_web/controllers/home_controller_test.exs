defmodule ElixirCollectathonWeb.HomeControllerTest do
  use ElixirCollectathonWeb.ConnCase

  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server

  describe "index/2" do
    test "renders home page", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Elixir Collectathon"
    end

    test "clears game session data", %{conn: conn} do
      # Setup a session with game data
      conn =
        conn
        |> init_test_session(%{game_id: "some_game", player: "some_player"})
        |> get(~p"/")

      assert get_session(conn, :game_id) == nil
      assert get_session(conn, :player) == nil
    end

    test "handles existing game session by leaving game", %{conn: conn} do
      # Create a real game to test leaving logic
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      # Verify player is in game
      game_state = :sys.get_state(Server.via_tuple(game_id))
      assert Map.has_key?(game_state.players, "Alice")

      # Visit home with session data
      conn
      |> init_test_session(%{game_id: game_id, player: "Alice"})
      |> get(~p"/")

      # Let's give it a tiny bit of time for the cast to be processed
      Process.sleep(50)

      game_state = :sys.get_state(Server.via_tuple(game_id))
      refute Map.has_key?(game_state.players, "Alice")
    end

    test "passes params to live render", %{conn: conn} do
      conn = get(conn, ~p"/?form_view=join-game&game_id=ABC")
      assert html_response(conn, 200) =~ "join-game"
      assert html_response(conn, 200) =~ "ABC"
    end
  end
end
