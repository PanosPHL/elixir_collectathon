defmodule ElixirCollectathon.Games.Server do
  alias ElixirCollectathon.Players.Player
  use GenServer

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def via_tuple(game_id) do
    {:via, Registry, {ElixirCollectathon.Games.Registry, game_id}}
  end

  def add_player(game_id, player_name) do
    GenServer.call(via_tuple(game_id), {:add_player, player_name})
  end

  @impl GenServer
  def init(game_id) do
    {:ok, ElixirCollectathon.Games.Game.new(game_id)}
  end

  @impl GenServer
  def handle_call({:add_player, player_name}, _from, state) do
    new_state =
      %{
        state
        | players:
            Map.put(
              state.players,
              player_name,
              Player.new(player_name)
            )
      }

    {:reply, :ok, new_state}
  end
end
