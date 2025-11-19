defmodule ElixirCollectathonWeb.GameController do
  @moduledoc """
  Controller for game-related HTTP actions.

  Handles non-LiveView game actions such as joining a game via POST request.
  """
  alias ElixirCollectathonWeb.Routes
  use ElixirCollectathonWeb, :controller

  @doc """
  Handles POST requests to join a game.

  Stores the player name in the session and redirects to the controller view
  where the player can control their character.

  ## Parameters
    - `conn` - The Plug.Conn struct
    - `params` - Map containing "game_id" and "player_name"
  """

  @spec join_game(Plug.Conn.t(), %{optional(String.t()) => String.t()}) :: Plug.Conn.t()
  def join_game(conn, %{"game_id" => game_id, "player_name" => player_name}) do
    conn
    |> put_session(:player, player_name)
    |> redirect(to: Routes.controller(game_id))
  end
end
