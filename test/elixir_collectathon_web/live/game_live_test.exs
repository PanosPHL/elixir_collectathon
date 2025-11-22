defmodule ElixirCollectathonWeb.GameLiveTest do
  alias ElixirCollectathonWeb.Routes
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb.ConnCase
  use ElixirCollectathonWeb.LiveViewCase

  setup do
    {:ok, game_id} = GameSupervisor.create_game()

    Phoenix.PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    %{game_id: game_id}
  end

  describe "mount/3" do
    test "redirects to home if game does not exist", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "Game not found."}}}} =
               live(conn, Routes.game("nonexistent-game-id"))
    end

    test "mounts successfully if game exists", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert has_element?(view, "#game-canvas")
    end
  end

  describe "QR code, countdown, or no content on top of game canvas" do
    test "has QR code loading by default", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert has_element?(view, "#game-qr-code")
    end

    test "shows QR code once it has loaded", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      assert render_async(view) =~ "svg"
    end

    test "shows countdown when countdown is active", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      # Simulate starting the countdown, I'm sure it can be done via DOM events
      # but having trouble figuring it out right now

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        {:countdown, 3}
      )

      assert has_element?(view, "#game-countdown")
      refute has_element?(view, "#game-qr-code")
    end

    test "shows no content on top of game canvas when game has started", %{
      conn: conn,
      game_id: game_id
    } do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      Phoenix.PubSub.broadcast(
        ElixirCollectathon.PubSub,
        "game:#{game_id}",
        :game_started
      )

      assert has_element?(view, "#game-canvas")
      refute has_element?(view, "#game-qr-code")
      refute has_element?(view, "#game-countdown")
    end
  end

  describe "player list updates" do
    test "updates player list when players join", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      GameServer.join(game_id, "Alice")

      assert_receive {:state, _game_state}
      assert render(view) =~ "Alice"
    end

    test "updates player list when players leave", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      GameServer.join(game_id, "Bob")
      assert_receive {:state, _game_state}
      assert render(view) =~ "Bob"

      GameServer.leave(game_id, "Bob")
      assert_receive {:state, _game_state}
      refute render(view) =~ "Bob"
    end
  end

  describe "pushes game state to canvas" do
    test "pushes game state on player join", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, Routes.game(game_id))

      GameServer.join(game_id, "Charlie")

      assert_receive {:state, game_state}
      assert game_state.players |> Enum.any?(fn {_, p} -> p.name == "Charlie" end)

      assert_push_event(view, "game_update", ^game_state)
    end
  end
end
