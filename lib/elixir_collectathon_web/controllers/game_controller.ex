defmodule ElixirCollectathonWeb.GameController do
  alias ElixirCollectathonWeb.Routes
  use ElixirCollectathonWeb, :controller

  def join_game(conn, %{"game_id" => game_id, "player_name" => player_name}) do
    conn
    |> put_session(:player, player_name)
    |> redirect(to: Routes.controller(game_id))
  end
end
