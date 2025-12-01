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
  def index(conn, %{"form_view" => _form_view} = params) do
    conn
    |> leave_current_game()
    |> delete_game_session()
    |> live_render(ElixirCollectathonWeb.HomeLive, session: params)
  end

  def index(conn, _params) do
    conn
    |> leave_current_game()
    |> delete_game_session()
    |> live_render(ElixirCollectathonWeb.HomeLive)
  end

  defp delete_game_session(conn) do
    conn
    |> delete_session(:game_id)
    |> delete_session(:player)
  end

  defp leave_current_game(conn) do
    with game_id when is_binary(game_id) <- get_session(conn, :game_id),
         player when is_binary(player) <- get_session(conn, :player) do
      GameServer.leave(game_id, player)
    end

    conn
  end
end
