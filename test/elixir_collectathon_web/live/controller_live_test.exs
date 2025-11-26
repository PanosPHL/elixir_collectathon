defmodule ElixirCollectathonWeb.ControllerLiveTest do
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Game
  use ElixirCollectathonWeb.ConnCase
  use ElixirCollectathonWeb.LiveViewCase

  setup do
    {:ok, game_id} = GameSupervisor.create_game()

    Phoenix.PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    %{game_id: game_id}
  end

  describe "mount/3" do
    test "redirects to home if no player in session", %{conn: conn, game_id: game_id} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(conn, Routes.controller(game_id))
    end

    test "mounts successfully with player in session", %{conn: conn, game_id: game_id} do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, _view, _html} = live(conn, Routes.controller(game_id))
    end
  end

  describe "waiting for game, countdown, and game start" do
    test "shows waiting message when countdown/game not started", %{conn: conn, game_id: game_id} do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      assert render(view) =~ "Waiting for game to start"
    end

    test "starts countdown when enough players join", %{conn: conn, game_id: game_id} do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      GameServer.start_countdown(game_id)

      receive do
        {:countdown, _} ->
          assert render(view) =~ ~r"[1-3]|GO!"
      after
        1000 ->
          flunk("Did not receive countdown message")
      end
    end

    test "shows joystick when game starts", %{conn: conn, game_id: game_id} do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      GameServer.start_game(game_id)

      receive do
        :game_started ->
          assert has_element?(view, "#joystick-container")
      after
        1000 ->
          flunk("Did not receive game_started message")
      end
    end
  end

  describe "when a winner is declared" do
    test "shows a winner message to the player", %{conn: conn, game_id: game_id} do
      GameServer.join(game_id, "Bob")

      conn =
        conn
        |> init_test_session(%{"player" => "Bob", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {
          :state,
          %Game{Game.new("ABC123") | winner: "Bob"}
        }
      )

      assert render(view) =~ "Bob"
    end
  end

  describe "handling game server shutdown" do
    test "does nothing when the game server shuts down normally (i.e. a winner is declared)", %{
      conn: conn,
      game_id: game_id
    } do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:game_server_shutdown, :normal}
      )

      assert has_element?(view, "#waiting-for-game")
    end

    test "redirects to home when game server shuts down via timeout", %{
      conn: conn,
      game_id: game_id
    } do
      GameServer.join(game_id, "Alice")

      conn =
        conn
        |> init_test_session(%{"player" => "Alice", "game_id" => game_id})

      {:ok, view, _html} = live(conn, Routes.controller(game_id))

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:game_server_shutdown, :timeout}
      )

      assert_redirect(view, Routes.home())
    end
  end
end
