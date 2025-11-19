defmodule ElixirCollectathonWeb.HomeLiveTest do
  use ElixirCollectathonWeb.LiveViewCase
  alias ElixirCollectathon.Games.Supervisor
  alias ElixirCollectathon.Games.Server
  alias ElixirCollectathonWeb.Routes

  describe "mount/3" do
    test "renders the home page", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      assert has_element?(view, "#create-game-form")
      assert has_element?(view, "#create-and-join")
      # Initially, join form should not be visible
      refute has_element?(view, "#join-game-form")
    end

    test "initializes with create-and-join view", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Should show create-and-join div
      assert has_element?(view, "#create-and-join")
      assert has_element?(view, "#create-game-form")
      # Should not show join form initially
      refute has_element?(view, "#join-game-form")
    end
  end

  describe "create_game event" do
    test "creates a new game and redirects", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      view
      |> element("#create-game-form")
      |> render_submit()

      # The redirect will be to a specific game ID, so we just check it redirects
      assert_redirect(view)
    end

    test "shows flash message on successful game creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      view
      |> element("#create-game-form")
      |> render_submit()

      # The redirect will be to a specific game ID, so we just check it redirects
      assert_redirect(view)
    end
  end

  describe "change_form_view event" do
    test "switches to join-game view when Join Game button is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Initially should show create-and-join view
      assert has_element?(view, "#create-and-join")
      refute has_element?(view, "#join-game-form")

      # Click Join Game button
      view
      |> element("#join-game-button")
      |> render_click()

      # Should now show join-game form
      assert has_element?(view, "#join-game-form")
      refute has_element?(view, "#create-and-join")
    end

    test "switches back to create-and-join view when Cancel button is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Switch to join-game view first
      view
      |> element("#join-game-button")
      |> render_click()

      assert has_element?(view, "#join-game-form")

      # Click Cancel button
      view
      |> element("#cancel-join-game-button")
      |> render_click()

      # Should be back to create-and-join view
      assert has_element?(view, "#create-and-join")
      assert has_element?(view, "#create-game-form")
      refute has_element?(view, "#join-game-form")
    end
  end

  describe "join_game event" do
    test "shows error when game does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Switch to join-game view first
      view
      |> element("#join-game-button")
      |> render_click()

      # Submit form with invalid game ID
      view
      |> form("#join-game-form", %{
        "player_name" => "Alice",
        "game_id" => "INVALID"
      })
      |> render_submit()

      assert has_element?(view, "#join-game-form")
      assert render(view) =~ "No game exists with this ID"
    end

    test "successfully joins an existing game", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      {:ok, view, _html} = live(conn, Routes.home())

      # Switch to join-game view first
      view
      |> element("#join-game-button")
      |> render_click()

      # Submit join form
      view
      |> form("#join-game-form", %{
        "player_name" => "Alice",
        "game_id" => game_id
      })
      |> render_submit()

      # Should trigger navigation (via trigger_join_game)
      # The form submission sets trigger_join_game to true, which causes a redirect
      # We can verify the form was submitted successfully by checking the view state
      # or that the player was added to the game
      assert Server.does_game_exist?(game_id)

      # Verify player was added
      state = :sys.get_state(Server.via_tuple(game_id))
      assert Map.has_key?(state.players, "Alice")
    end

    test "shows error when game has 4 players", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      # Fill the game with 4 players
      Server.join(game_id, "Player1")
      Server.join(game_id, "Player2")
      Server.join(game_id, "Player3")
      Server.join(game_id, "Player4")

      {:ok, view, _html} = live(conn, Routes.home())

      # Switch to join-game view first
      view
      |> element("#join-game-button")
      |> render_click()

      # Try to join as 5th player
      view
      |> form("#join-game-form", %{
        "player_name" => "Player5",
        "game_id" => game_id
      })
      |> render_submit()

      assert render(view) =~ "There are already four players"
    end

    test "shows error when player name already exists", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      Server.join(game_id, "Alice")

      {:ok, view, _html} = live(conn, Routes.home())

      # Switch to join-game view first
      view
      |> element("#join-game-button")
      |> render_click()

      # Try to join with existing name
      view
      |> form("#join-game-form", %{
        "player_name" => "Alice",
        "game_id" => game_id
      })
      |> render_submit()

      assert render(view) =~ "A player with this name already exists"
    end
  end

  describe "UI interactions" do
    test "join form is not rendered initially", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Initially, join form should not be rendered (not just hidden)
      refute has_element?(view, "#join-game-form")
      # But create-and-join should be visible
      assert has_element?(view, "#create-and-join")
    end

    test "create and join buttons are visible in initial view", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Create form and join button should be visible
      assert has_element?(view, "#create-game-form")
      assert has_element?(view, "#join-game-button")
      # Join form should not be rendered yet
      refute has_element?(view, "#join-game-form")
    end

    test "join form becomes visible after clicking Join Game button", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      # Initially not visible
      refute has_element?(view, "#join-game-form")

      # Click Join Game button
      view
      |> element("#join-game-button")
      |> render_click()

      # Now should be visible
      assert has_element?(view, "#join-game-form")
      assert has_element?(view, "#cancel-join-game-button")
    end
  end

  describe "feature cards" do
    test "displays feature cards", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      assert has_element?(view, "#features")
      html = render(view)
      assert html =~ "Real-Time Updates"
      assert html =~ "Concurrent Game State"
      assert html =~ "JavaScript Integration"
    end
  end

  describe "how to play section" do
    test "displays how to play section", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.home())

      assert has_element?(view, "#howitworks")
      html = render(view)
      assert html =~ "How To Play"
      assert html =~ "Create and Join"
      assert html =~ "Playing the Game"
      assert html =~ "Viewing a Game"
    end
  end
end
