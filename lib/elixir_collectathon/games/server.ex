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
  alias __MODULE__, as: GameServer
  use GenServer

  defguard has_four_players?(players) when map_size(players) >= 4

  # 30 Hz
  @tick_rate 33

  @inactivity_limit_ms :timer.minutes(10)

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
  Returns a child specification for starting this GenServer under a DynamicSupervisor.

  This function is used by DynamicSupervisor to start game server processes.
  Each game server is configured to restart as `:temporary`, meaning it will
  not be restarted if it crashes—instead, the supervisor will clean up the process.

  ## Parameters
    - `game_id` - A unique identifier for the game

  ## Returns
    - A map with the child spec including id, start tuple, restart strategy, and type

  ## Examples

      iex> spec = ElixirCollectathon.Games.Server.child_spec("ABC123")
      iex> spec.id
      ElixirCollectathon.Games.Server
      iex> spec.restart
      :temporary
      iex> spec.type
      :worker
  """

  @spec child_spec(String.t()) :: %{
          id: atom(),
          start: {atom(), atom(), [String.t()]},
          restart: atom(),
          type: atom()
        }
  def child_spec(game_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game_id]},
      restart: :temporary,
      type: :worker
    }
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
  Begins the countdown to start a game.

  ## Parameters
  - `game_id` - The ID of the game to begin the countdown on

  ## Returns
  - `:ok` - The request to begin the countdown was sent successfully

  ## Examples

    Server.start_countdown("ABC123")
    # => :ok
  """

  @spec start_countdown(String.t()) :: :ok
  def start_countdown(game_id) do
    GenServer.cast(via_tuple(game_id), :start_countdown)
  end

  @doc """
  Starts the game instance, usually after the countdown has completed.

  ## Parameters
    - `game_id` - The ID of the game to start

  ## Returns
    - `:ok` - The request to start the game was sent successfully

  ## Examples

      Server.start_game("ABC123")
      # => :ok
  """
  def start_game(game_id) do
    GenServer.cast(via_tuple(game_id), :start_game)
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

  @spec update_velocity(String.t(), String.t(), Player.velocity()) :: :ok
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
  @spec init(String.t()) :: {:ok, Game.t(), integer()}
  # Instantiates a game instance with inactivity timeout
  def init(game_id) do
    {
      :ok,
      game_id
      |> Game.new(),
      @inactivity_limit_ms
    }
  end

  @impl GenServer
  @spec handle_call({:join, String.t()}, GenServer.from(), Game.t()) ::
          {:reply, {:error, :max_players_reached}, Game.t()}
  # Callback to handle a player joining when the max amount of players (4) has been reached
  def handle_call({:join, _player_name}, _from, %Game{players: players} = state)
      when has_four_players?(players) do
    {:reply, {:error, :max_players_reached}, state}
  end

  @impl GenServer
  @spec handle_call({:join, String.t()}, GenServer.from(), Game.t()) ::
          {:reply, :ok | {:error, :max_players_reached} | {:error, :already_added}, Game.t()}
  # Callback to handle joining depending on whether or not a player with that name
  # has already joined
  def handle_call({:join, player_name}, _from, %Game{next_player_num: next_player_num} = state) do
    case Game.has_player?(state, player_name) do
      false ->
        new_state =
          state
          |> Game.spawn_player(player_name, next_player_num)
          |> Game.update_last_activity_at()

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

  @impl GenServer
  @spec handle_call({:join, String.t()}, GenServer.from(), Game.t()) ::
          {:reply, {:error, :game_already_started}, Game.t()}
  # Callback to handle joining when the game has already been started
  def handle_call({:join, _player_name}, _from, %Game{is_running: true} = state) do
    {:reply, {:error, :game_already_started}, state}
  end

  @impl GenServer
  @spec handle_cast({:leave, String.t()}, Game.t()) :: {:noreply, Game.t()}
  # Callback to remove a player when they navigate away from the Controller/Joystick view
  def handle_cast({:leave, player_name}, %Game{} = state) do
    new_state =
      state
      |> Game.remove_player(player_name)
      |> Game.update_last_activity_at()

    broadcast(new_state)

    {:noreply, new_state}
  end

  @impl GenServer
  @spec handle_cast(:start_countdown, Game.t()) :: {:noreply, Game.t()}
  # Callback to start the countdown when the game is not already running
  def handle_cast(:start_countdown, %Game{is_running: false} = state) do
    Process.send_after(self(), :countdown_tick, 1000)

    broadcast(state.game_id, {:countdown, state.countdown})

    {
      :noreply,
      state
      |> Game.countdown_to_start()
      |> Game.update_last_activity_at()
    }
  end

  @impl GenServer
  @spec handle_cast(:start_game, Game.t()) :: {:noreply, Game.t()}
  # Callback to start the game when the game is not already started
  def handle_cast(:start_game, %Game{is_running: false} = state) do
    {:ok, timer_ref} = :timer.send_interval(@tick_rate, :tick)

    new_state =
      state
      |> Game.start(timer_ref)
      |> Game.update_last_activity_at()

    broadcast(new_state.game_id, :game_started)

    {:noreply, new_state}
  end

  @impl GenServer
  @spec handle_cast({:velocity, String.t(), Player.velocity()}, Game.t()) :: {:noreply, Game.t()}
  # Callback for noop when player tries to update their velocity and the game has not been started
  def handle_cast({:velocity, _player_name, _velocity}, %Game{is_running: false} = state) do
    {:noreply, state}
  end

  @impl GenServer
  @spec handle_cast({:velocity, String.t(), Player.velocity()}, Game.t()) ::
          {:noreply, Game.t()}
  # Callback to handle player velocity update when the game has started
  def handle_cast({:velocity, player_name, {x, y}}, %Game{is_running: true} = state) do
    {
      :noreply,
      state
      |> Game.update_player_velocity(player_name, {x, y})
      |> Game.update_last_activity_at()
    }
  end

  @impl GenServer
  @spec handle_info(:countdown_tick, Game.t()) :: {:noreply, Game.t()}
  # Callback to handle the :countdown_tick message when the countdown value is an integer (i.e. 3, 2, 1)
  def handle_info(:countdown_tick, %Game{countdown: n, is_running: false} = state)
      when is_integer(n) and n > 0 do
    broadcast(state.game_id, {:countdown, n})

    Process.send_after(self(), :countdown_tick, 1000)

    {
      :noreply,
      state
      |> Game.countdown_to_start()
      |> Game.update_last_activity_at()
    }
  end

  @impl GenServer
  @spec handle_info(:countdown_tick, Game.t()) :: {:noreply, Game.t()}
  # Callback to handle starting the game when the countdown value is "GO!"
  def handle_info(
        :countdown_tick,
        %Game{countdown: "GO!", game_id: game_id, is_running: false} = state
      ) do
    broadcast(game_id, {:countdown, state.countdown})

    :timer.apply_after(1000, GameServer, :start_game, [
      game_id
    ])

    {
      :noreply,
      state
      |> Game.update_last_activity_at()
    }
  end

  @impl GenServer
  @spec handle_info(:countdown_tick, Game.t()) :: {:noreply, Game.t()}
  # Callback for noop when a :countdown_tick message is received and a game has already started
  def handle_info(:countdown_tick, %Game{is_running: true} = state) do
    {:noreply, state}
  end

  @impl GenServer
  @spec handle_info(:tick, Game.t()) :: {:noreply, Game.t()}
  # Callback handle game ticks when the game is running. If the inactivity limit is passed,
  # the game server times out and shuts down. Otherwise, the game continues as normal.
  def handle_info(:tick, %Game{is_running: true, last_activity_at: last_activity_at} = state) do
    now = System.monotonic_time(:millisecond)

    if now - last_activity_at > @inactivity_limit_ms do
      send(self(), {:shutdown_game, :timeout})

      {:noreply, state}
    else
      %Game{current_letter: current_letter, winner: winner, timer_ref: timer_ref} =
        updated_state =
        Game.update_game_state(state)

      broadcast(updated_state)

      cond do
        # If there is a winner, cancel the game ticks and stop the game
        winner ->
          :timer.cancel(timer_ref)

          # Shutdown game process after 300ms to ensure LiveViews have time to receive updated state
          Process.send_after(self(), {:shutdown_game, :normal}, 300)

          {:noreply, updated_state |> Game.stop()}

        # If the game is running and there is no current letter spawned, spawn one
        is_nil(current_letter) ->
          {:noreply, updated_state |> Game.spawn_letter()}

        # Otherwise, just return the game state
        true ->
          {:noreply, updated_state}
      end
    end
  end

  @impl GenServer
  @spec handle_info(:tick, Game.t()) :: {:noreply, Game.t()}
  # Callback for noop when a game tick message is received and the game is not running
  def handle_info(:tick, %Game{is_running: false} = state) do
    {:noreply, state}
  end

  @impl GenServer
  @spec handle_info(:spawn_letter, Game.t()) :: {:noreply, Game.t()}
  # Callback to handle spawning a letter upon the :spawn_letter message
  def handle_info(:spawn_letter, %Game{} = state) do
    {
      :noreply,
      state
      |> Game.spawn_letter()
      |> Game.update_last_activity_at()
    }
  end

  @impl GenServer
  @spec handle_info({:shutdown_game, :normal | :timeout}, Game.t()) :: {:stop, :normal, Game.t()}
  # Callback to handle stopping the game process
  def handle_info(
        {:shutdown_game, reason},
        %Game{game_id: game_id, timer_ref: timer_ref} = state
      ) do
    if timer_ref, do: :timer.cancel(timer_ref)

    broadcast(game_id, {:game_server_shutdown, reason})

    {
      :stop,
      :normal,
      state
      |> Game.stop()
    }
  end

  @impl GenServer
  @spec handle_info(:timeout, Game.t()) :: {:noreply, Game.t()}
  # Callback to handle the :timeout send a new message to shut down
  # the game server.
  def handle_info(:timeout, %Game{} = state) do
    send(self(), {:shutdown_game, :timeout})

    {:noreply, state}
  end

  # Private functions
  @spec broadcast(String.t(), any()) :: :ok
  defp broadcast(game_id, payload) do
    PubSub.broadcast(
      ElixirCollectathon.PubSub,
      "game:#{game_id}",
      payload
    )
  end

  @spec broadcast(Game.t()) :: :ok
  defp broadcast(%Game{} = state) do
    PubSub.broadcast(
      ElixirCollectathon.PubSub,
      "game:#{state.game_id}",
      {:state, state}
    )
  end
end
