defmodule ElixirCollectathon.Games.Server do
  @moduledoc """
  GenServer process that manages the state and logic for a single game instance.

  This server:
  - Manages game state including players, positions, and game ticks
  - Handles player joining and velocity updates
  - Broadcasts game state updates via PubSub at 30 Hz (every 33ms)
  - Updates player positions based on their velocity each tick
  - Enforces game rules (max 4 players, unique player names)

  The server is registered in a Registry using the game_id as the key,
  allowing it to be found and accessed by other processes.
  """
  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Players.Player
  use GenServer

  # 30 Hz
  @tick_rate 33
  @box_lw 40
  @movement_speed 15
  @letters ~w(E L I X I R)

  @doc """
  Starts a new game server process linked to the current process.

  The server is registered in the Registry using the game_id.

  ## Parameters
    - `game_id` - A unique identifier for the game

  ## Returns
    - `{:ok, pid}` - If the server started successfully
    - `{:error, reason}` - If the server failed to start

  ## Examples

      {:ok, pid} = Server.start_link("ABC123")
  """

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  @doc """
  Returns the via tuple for registering/finding the server in the Registry.

  ## Parameters
    - `game_id` - The game ID to create the via tuple for

  ## Examples

      iex> ElixirCollectathon.Games.Server.via_tuple("ABC123")
      {:via, Registry, {ElixirCollectathon.Games.Registry, "ABC123"}}
  """

  @spec via_tuple(String.t()) :: {:via, Registry, {ElixirCollectathon.Games.Registry, String.t()}}
  def via_tuple(game_id) do
    {:via, Registry, {ElixirCollectathon.Games.Registry, game_id}}
  end

  @doc """
  Attempts to add a player to the game.

  ## Parameters
    - `game_id` - The ID of the game to join
    - `player_name` - The name of the player joining

  ## Returns
    - `:ok` - Player successfully joined
    - `{:error, :max_players_reached}` - Game already has 4 players
    - `{:error, :already_added}` - A player with this name already exists

  ## Examples

      Server.join("ABC123", "Alice")
      # => :ok
  """

  @spec join(String.t(), String.t()) ::
          :ok | {:error, :max_players_reached} | {:error, :already_added} | {:error, atom()}
  def join(game_id, player_name) do
    GenServer.call(via_tuple(game_id), {:join, player_name})
  end

  @doc """
  Removes a player from the game.

  ## Parameters
    - `game_id` - The ID of the game to leave
    - `player_name` - The name of the player leaving

  ## Returns
    - `:ok` - The request to leave was sent successfully

  ## Examples

      Server.leave("ABC123", "Alice")
      # => :ok
  """
  @spec leave(String.t(), String.t()) :: :ok
  def leave(game_id, player_name) do
    GenServer.cast(via_tuple(game_id), {:leave, player_name})
  end

  @doc """
  Updates the velocity of a player in the game.

  The velocity is a tuple of {x, y} values, typically in the range [-1, 1],
  representing the direction and speed of movement.

  ## Parameters
    - `game_id` - The ID of the game
    - `player_name` - The name of the player whose velocity to update
    - `{x, y}` - A tuple representing the velocity vector

  ## Examples

      Server.update_velocity("ABC123", "Alice", {1, 0})
      # => :ok (moves right)
  """

  @spec update_velocity(String.t(), String.t(), {integer(), integer()}) :: :ok
  def update_velocity(game_id, player_name, {x, y}) do
    GenServer.cast(via_tuple(game_id), {:velocity, player_name, {x, y}})
  end

  @doc """
  Checks if a game server process exists for the given game ID.

  ## Parameters
    - `game_id` - The game ID to check

  ## Returns
    - `true` - If a server process exists
    - `false` - If no server process exists

  ## Examples

      Server.does_game_exist?("ABC123")
      # => true
  """

  @spec does_game_exist?(String.t()) :: boolean()
  def does_game_exist?(game_id) do
    not is_nil(GenServer.whereis(via_tuple(game_id)))
  end

  # GenServer callbacks

  @impl GenServer
  @spec init(String.t()) :: {:ok, Game.t()}
  def init(game_id) do
    :timer.send_interval(@tick_rate, :tick)
    {
      :ok,
      game_id
      |> Game.new()
    }
  end

  @impl GenServer
  @spec handle_call({:join, String.t()}, GenServer.from(), Game.t()) ::
          {:reply, :ok | {:error, :max_players_reached} | {:error, :already_added}, Game.t()}
  def handle_call({:join, player_name}, _from, %Game{} = state) do
    if has_four_players?(state.players) do
      {:reply, {:error, :max_players_reached}, state}
    else
      case Game.has_player?(state, player_name) do
        false ->
          new_state =
            state
            |> Game.add_player(Player.new(player_name, state.next_player_num))

          broadcast(new_state)

          {
            :reply,
            :ok,
            new_state
          }

        true ->
          {:reply, {:error, :already_added}, state}
      end
    end
  end

  @impl GenServer
  @spec handle_cast({:leave, String.t()}, Game.t()) :: {:noreply, Game.t()}
  def handle_cast({:leave, player_name}, %Game{} = state) do
    {
      :noreply,
      state
      |> Game.remove_player(player_name)
    }
  end

  @impl GenServer
  @spec handle_cast({:velocity, String.t(), {integer(), integer()}}, Game.t()) ::
          {:noreply, Game.t()}
  def handle_cast({:velocity, player_name, {x, y}}, %Game{} = state) do
    players =
      state.players
      |> Map.replace(player_name, Player.set_velocity(state.players[player_name], {x, y}))

    {
      :noreply,
      state
      |> Game.set_players(players)
    }
  end

  @impl GenServer
  @spec handle_info(:tick, Game.t()) :: {:noreply, Game.t()}
  def handle_info(:tick, %Game{} = state) do
    updated_state =
      update_state(state)

    broadcast(updated_state)

    {:noreply, updated_state}
  end

  # Private functions
  @spec broadcast(Game.t()) :: :ok
  defp broadcast(%Game{} = state) do
    PubSub.broadcast(
      ElixirCollectathon.PubSub,
      "game:#{state.game_id}",
      {:state, state}
    )
  end

  @spec update_state(Game.t()) :: Game.t()
  defp update_state(%Game{} = state) do
    players =
      Map.new(state.players, fn {player_name, player} ->
        {player_name, update_player_position(player)}
      end)

    %Game{state | players: players, tick_count: state.tick_count + 1}
  end

  @spec update_player_position(Player.t()) :: Player.t()
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

  @spec clamp(non_neg_integer(), 0, non_neg_integer()) :: non_neg_integer()
  defp clamp(v, min, max), do: max(min(v, max), min)

  @spec has_four_players?(%{optional(String.t()) => Player.t()}) :: boolean()
  defp has_four_players?(players), do: length(Map.to_list(players)) == 4
end
