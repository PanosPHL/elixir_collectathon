defmodule ElixirCollectathonWeb.HomeController do
  @moduledoc """
  Controller for the home page.
  """
  use ElixirCollectathonWeb, :controller
  alias ElixirCollectathon.Games.Server, as: GameServer
  import Phoenix.LiveView.Controller

  @doc"""
  Renders the homepage.

  If a user has an active session from a previous game, like a previous visit
  or navigating back to the homepage, it will clear the game_id and player's name
  from the session.

  ## Parameters
  - `conn` - The Plug.Conn struct
  - `params` - An unused map of the params
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    case get_session(conn) do
      %{"game_id" => game_id, "player" => player} ->
        GameServer.leave(game_id, player)

        _ -> nil
    end

    conn
    |> delete_session(:game_id)
    |> delete_session(:player)
    |> live_render(ElixirCollectathonWeb.HomeLive)
    end
end
