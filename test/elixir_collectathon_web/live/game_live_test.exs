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

      assert render(view) =~ "Alice"
    end

    test "renders QR code", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Wait for async assignment to complete
      Process.sleep(100)

      assert render(view) =~ "<svg"
    end

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

  describe "countdown" do
    test "handles countdown updates from PubSub", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Simulate a countdown broadcast
      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:countdown, 3}
      )

      # View should handle the message without crashing
      assert render(view) =~ "3"
    end
  end

  describe "game start" do
    test "handles game start from PubSub", %{conn: conn} do
      {:ok, game_id} = Supervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Simulate a game start broadcast
      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        :game_started
      )

      refute has_element?(view, "#game-countdown")
      refute has_element?(view, "#game-qr-code")
      assert has_element?(view, "#game-canvas")
    end
  end
end
