defmodule ElixirCollectathonWeb.Routes do
  use ElixirCollectathonWeb, :verified_routes

  def home, do: ~p"/"

  def game(game_id) do
    ~p"/games/#{game_id}"
  end

  def controller(game_id, player_name) do
    ~p"/controller/#{game_id}?player=#{player_name}"
  end
end
