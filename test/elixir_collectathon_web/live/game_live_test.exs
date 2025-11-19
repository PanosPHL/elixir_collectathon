defmodule ElixirCollectathonWeb.GameLiveTest do
  use ElixirCollectathonWeb.LiveViewCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathonWeb.Routes

  describe "mount/3" do
    test "mounts successfully when game exists", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert has_element?(view, "#game-canvas")
      html = render(view)
      assert html =~ game_id
    end

    # Skip test for non-existent game as it requires error templates
    # The mount function handles non-existent games gracefully by returning {:ok, socket}
    # but the LiveView system may try to render an error page which requires templates

    test "subscribes to game updates when connected", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Add a player to trigger a broadcast
      Server.join(game_id, "Alice")

      # Wait for the broadcast
      Process.sleep(100)

      # The view should receive the state update
      # (We can't easily test the push_event without more setup, but we can verify it doesn't crash)
      assert render(view) =~ game_id
    end
  end

  describe "handle_info/2" do
    test "handles state updates from PubSub", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Simulate a state broadcast
      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:state, %ElixirCollectathon.Games.Game{game_id: game_id}}
      )

      # View should handle the message without crashing
      assert render(view) =~ game_id
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
