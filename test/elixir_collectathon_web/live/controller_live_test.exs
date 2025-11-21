defmodule ElixirCollectathonWeb.ControllerLiveTest do
  use ElixirCollectathonWeb.LiveViewCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathonWeb.Routes

  describe "mount/3" do
    test "mounts successfully with game_id, player name, and game_is_running (false)", %{
      conn: conn
    } do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      assert has_element?(view, "#waiting-for-game")
    end

    test "shows flash message on mount", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      assert render(view) =~ "Successfully joined game"
    end

    test "redirects to home when session is missing", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      # No session data
      {:error, {:live_redirect, %{to: "/"}}} = live(conn, Routes.controller(game_id))
    end
  end

  describe "countdown display" do
    test "renders countdown when countdown it is active", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(ElixirCollectathon.PubSub, "game:#{game_id}", {:countdown, 3})

      assert render(view) =~ "3"
    end
  end

  describe "joystick display" do
    test "renders joystick when game is running", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      Server.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("player", "Alice")

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(ElixirCollectathon.PubSub, "game:#{game_id}", :game_started)

      assert has_element?(view, "#joystick-container")
      assert has_element?(view, "#joystick-handle")
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

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(ElixirCollectathon.PubSub, "game:#{game_id}", :game_started)

      # Trigger the event via the view
      render_hook(view, "joystick_move", %{"x" => 0.5, "y" => -0.5})

      # Verify velocity was updated
      state = :sys.get_state(Server.via_tuple(game_id))
      assert state.players["Alice"].velocity == {0.5, -0.5}
    end
  end
end
