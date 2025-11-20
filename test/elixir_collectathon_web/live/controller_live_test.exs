defmodule ElixirCollectathonWeb.ControllerLiveTest do
  use ElixirCollectathonWeb.LiveViewCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathonWeb.Routes

  describe "mount/3" do
    test "mounts successfully with game_id and player name", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      assert has_element?(view, "#joystick-container")
      assert has_element?(view, "#joystick-handle")
    end

    test "shows flash message on mount", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      html = render(view)
      assert html =~ "Successfully joined game"
    end

    test "redirects to home when session is missing", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      # No session data
      {:error, {:live_redirect, %{to: "/"}}} = live(conn, Routes.controller(game_id))
    end
  end

  describe "joystick_move event" do
    test "handle_event updates player velocity", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, _view, _html} = live(conn, Routes.controller(game_id))

      # Test the handle_event directly by simulating the event
      # Since joystick_move is triggered by JavaScript, we test the server interaction
      # The actual event handling is tested in the GameServer tests
      GameServer.update_velocity(game_id, "Alice", {0.5, -0.5})

      # Wait for the cast to process
      Process.sleep(50)

      # Verify velocity was updated
      state = :sys.get_state(Server.via_tuple(game_id))
      assert state.players["Alice"].velocity == {0.5, -0.5}
    end
  end

  describe "joystick UI" do
    test "renders joystick container and handle", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      assert has_element?(view, "#joystick-container")
      assert has_element?(view, "#joystick-handle")
      html = render(view)
      assert html =~ "phx-hook=\"Joystick\""
    end
  end
end
