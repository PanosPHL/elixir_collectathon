defmodule ElixirCollectathonWeb.GameLiveTest do
  use ElixirCollectathonWeb.LiveViewCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  alias ElixirCollectathonWeb.Routes

  describe "mount/3" do
    test "mounts successfully when game exists", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert has_element?(view, "#game-canvas")
    end

    test "redirects to home page when game does not exist", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, Routes.game("non_existent_game_id"))

      assert path == Routes.home()
    end

    test "subscribes to game updates when connected", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Add a player to trigger a broadcast
      Server.join(game_id, "Alice")

      # Wait for the broadcast
      Process.sleep(100)

      # The view should receive the state update
      # (We can't easily test the push_event without more setup, but we can verify it doesn't crash)
      assert render(view) =~ "Alice"
    end
  end

  describe "handle_info/2" do
    test "handles state updates from PubSub", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Simulate a state broadcast
      player = Player.new("Bob", 1)
      game = %Game{game_id: game_id, players: %{"Bob" => player}}

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:state, game}
      )

      # View should handle the message without crashing
      assert render(view) =~ "Bob"
    end
  end

  describe "game canvas" do
    test "renders canvas with correct attributes", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert has_element?(view, "#game-canvas")
      html = render(view)
      assert html =~ "width=\"1024\""
      assert html =~ "height=\"576\""
      assert html =~ "phx-hook=\"Game\""
    end
  end
end
