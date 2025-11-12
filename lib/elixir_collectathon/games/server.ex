defmodule ElixirCollectathon.Games.Server do
  use GenServer

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def via_tuple(game_id) do
    {:via, Registry, {ElixirCollectathon.Games.Registry, game_id}}
  end

  def init(game_id) do
    {:ok, ElixirCollectathon.Games.Game.new(game_id)}
  end
end
