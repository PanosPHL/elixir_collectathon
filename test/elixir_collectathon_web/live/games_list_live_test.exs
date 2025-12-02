defmodule ElixirCollectathonWeb.GamesListLiveTest do
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  use ElixirCollectathonWeb.ConnCase
  use ElixirCollectathonWeb.LiveViewCase

  describe "mount/3" do
    test "mounts with no game_ids when there are no games created", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.games_list())

      assert has_element?(view, "#no-games")
    end

    test "renders a list of game_ids when there is at least one game created", %{conn: conn} do
      {:ok, game_id} = GameSupervisor.create_game()

      {:ok, view, _html} = live(conn, Routes.games_list())

      assert has_element?(view, "#game_#{game_id}")
    end
  end

  describe "handle_info/2" do
    test "adds a game when a new one has been created", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.games_list())

      assert has_element?(view, "#no-games")

      {:ok, game_id} = GameSupervisor.create_game()

      assert has_element?(view, "#game_#{game_id}")
    end
  end
end
