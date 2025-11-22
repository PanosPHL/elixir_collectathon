defmodule ElixirCollectathonWeb.HomeLiveTest do
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathonWeb.Routes
  use ElixirCollectathonWeb.ConnCase
  use ElixirCollectathonWeb.LiveViewCase

  describe "mount/3" do
    test "assigns default values", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home())

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "#create-and-join")
    end

    test "assigns the form_view from params", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "#join-game-form")
    end

    test "assigns the form_view and game_id from params", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home("join-game", "12345"))

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "#join-game-form")
      assert has_element?(view, "input[value='12345']")
    end
  end

  describe "creating a game" do
    test "creates a new game and redirects to the game page", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home())

      {:ok, view, _html} = live(conn)

      assert {:error, {:live_redirect, %{to: _to}}} =
               view
               |> form("#create-game-form", %{})
               |> render_submit()
    end
  end

  describe "changing \"form view\"" do
    test "updates the form_view to join-game", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home())

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "#create-and-join")

      view
      |> element("button", "Join Game")
      |> render_click()

      assert has_element?(view, "#join-game-form")
    end

    test "changes form_view back to create-and-join", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "#join-game-form")

      view
      |> element("button", "Cancel")
      |> render_click()

      assert has_element?(view, "#create-and-join")
    end
  end

  describe "joining a game" do
    test "shows error if game does not exist", %{conn: conn} do
      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      html =
        view
        |> form("#join-game-form", %{"player_name" => "Alice", "game_id" => "NONEXISTENT"})
        |> render_submit()

      assert html =~ "No game exists with this ID."
    end

    test "shows error if game is full", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      # Fill the game with max players
      for name <- ["Alice", "Bob", "Charlie", "Dave"] do
        :ok = GameServer.join(game_id, name)
      end

      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      html =
        view
        |> form("#join-game-form", %{"player_name" => "Eve", "game_id" => game_id})
        |> render_submit()

      assert html =~ "There are already four players in this game."
    end

    test "shows error if player name is already taken", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()
      :ok = GameServer.join(game_id, "Alice")

      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      html =
        view
        |> form("#join-game-form", %{"player_name" => "Alice", "game_id" => game_id})
        |> render_submit()

      assert html =~ "A player with this name already exists in this game."
    end

    test "successfully joins a game and redirects to the game page", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      conn =
        conn
        |> get(Routes.home("join-game"))

      {:ok, view, _html} = live(conn)

      form =
        form(view, "#join-game-form", %{
          "player_name" => "Alice",
          "game_id" => game_id
        })

      assert render_submit(form) =~ ~r"phx-trigger-action"

      {:ok, _view, html} =
        follow_trigger_action(form, conn)
        |> get(Routes.controller(game_id))
        |> live()

      assert html =~ "Waiting for game to start"
    end
  end
end
