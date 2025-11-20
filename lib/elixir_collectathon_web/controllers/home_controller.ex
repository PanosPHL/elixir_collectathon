defmodule ElixirCollectathonWeb.HomeController do
  @moduledoc """
  Controller for the home page.
  """
  use ElixirCollectathonWeb, :controller
  alias ElixirCollectathon.Games.Server, as: GameServer
  import Phoenix.LiveView.Controller

  @doc """
  Renders the homepage.

  If a user has an active session from a previous game, like a previous visit
  or navigating back to the homepage, it will clear the game_id and player's name
  from the session.

  ## Parameters
  - `conn` - The Plug.Conn struct
  - `params` - A map of the params
  """

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"form_view" => form_view, "game_id" => game_id}) do
    leave_current_game(conn)

    delete_game_session(conn)
    |> live_render(ElixirCollectathonWeb.HomeLive,
      session: %{"form_view" => form_view, "game_id" => game_id}
    )
  end

  def index(conn, %{"form_view" => form_view}) do
    leave_current_game(conn)

    delete_game_session(conn)
    |> live_render(ElixirCollectathonWeb.HomeLive, session: %{"form_view" => form_view})
  end

  def index(conn, _params) do
    leave_current_game(conn)

    delete_game_session(conn)
    |> live_render(ElixirCollectathonWeb.HomeLive)
  end

  defp delete_game_session(conn) do
    conn
    |> delete_session(:game_id)
    |> delete_session(:player)
  end

  defp leave_current_game(conn) do
    case get_session(conn) do
      %{"game_id" => game_id, "player" => player} ->
        GameServer.leave(game_id, player)

      _ ->
        nil
    end
  end
end
