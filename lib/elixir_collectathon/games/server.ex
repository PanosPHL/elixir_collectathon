defmodule ElixirCollectathon.Games.Server do
  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  use GenServer

  # 30 Hz
  @tick_rate 33
  @box_lw 40
  @movement_speed 15
  @letters ~w(E L I X I R)

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def via_tuple(game_id) do
    {:via, Registry, {ElixirCollectathon.Games.Registry, game_id}}
  end

  # Client interface functions
  def join(game_id, player_name) do
    GenServer.call(via_tuple(game_id), {:join, player_name})
  end

  def update_velocity(game_id, player_name, {x, y}) do
    GenServer.cast(via_tuple(game_id), {:velocity, player_name, {x, y}})
  end

  # GenServer callbacks
  @impl GenServer
  def init(game_id) do
    :timer.send_interval(@tick_rate, :tick)
    {:ok, Game.new(game_id)}
  end

  @impl GenServer
  def handle_call({:join, player_name}, _from, state) do
    dbg(length(Map.to_list(state.players)))

    if length(Map.to_list(state.players)) == 4 do
      {:reply, {:error, :max_players_reached}, state}
    else
      case Map.get(state, player_name) do
        ^player_name ->
          {:reply, {:error, :already_added}, state}

        nil ->
          new_state =
            Game.add_player(state, Player.new(player_name, state.next_player_num))

          {:reply, :ok, new_state}
      end
    end
  end

  @impl GenServer
  def handle_cast({:velocity, player_name, {x, y}}, state) do
    players =
      state.players
      |> Map.replace(player_name, Player.set_velocity(state.players[player_name], {x, y}))

    {:noreply, %{state | players: players}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    updated_state =
      update_state(state)

    broadcast(updated_state)

    {:noreply, updated_state}
  end

  defp broadcast(state) do
    PubSub.broadcast(
      ElixirCollectathon.PubSub,
      "game:#{state.game_id}",
      {:state, state}
    )
  end

  defp update_state(%Game{} = state) do
    players =
      Map.new(state.players, fn {player_name, player} ->
        {player_name, update_player_position(player)}
      end)

    %Game{state | players: players, tick_count: state.tick_count + 1}
  end

  defp update_player_position(
         %Player{position: player_position, velocity: player_velocity} = player
       ) do
    {x, y} = player_position
    {vx, vy} = player_velocity

    map_size = Game.get_map_size()

    new_position = {
      clamp(x + vx * @movement_speed, 0, elem(map_size, 0) - @box_lw),
      clamp(y + vy * @movement_speed, 0, elem(map_size, 1) - @box_lw)
    }

    Player.set_position(player, new_position)
  end

  defp clamp(v, min, max), do: max(min(v, max), min)
end
