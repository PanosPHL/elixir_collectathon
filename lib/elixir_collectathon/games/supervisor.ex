defmodule ElixirCollectathon.Games.Supervisor do
  @moduledoc """
  Dynamic supervisor for managing game server processes.

  This module provides functionality to create new game instances by
  starting game server processes under a DynamicSupervisor. It handles
  collision detection and retries when generating unique game IDs.

  Games are supervised and will be restarted if they crash.
  """
  alias ElixirCollectathon.Games.Server, as: GameServer

  @doc """
  Creates a new game by starting a game server process.

  Generates a unique game ID and starts a new game server under the
  DynamicSupervisor. If a collision occurs (game ID already exists),
  it will retry up to 5 times.

  ## Parameters
    - `count` - Internal counter for retry attempts (default: 0)

  ## Returns
    - `{:ok, game_id}` - If the game was created successfully
    - `{:error, :max_retries}` - If 5 attempts failed to create a unique game

  ## Examples

      Supervisor.create_game()
      # => {:ok, "A1B2C3D4"}
  """

  @spec create_game(non_neg_integer()) :: {:ok, String.t()} | {:error, :max_retries}
  def create_game(count \\ 0) do
    game_id = ElixirCollectathon.Utils.generate_code()

    cond do
      count <= 5 ->
        if GameServer.does_game_exist?(game_id) do
          create_game(count + 1)
        else
          case DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id}) do
            {:ok, _server_pid} -> {:ok, game_id}
            {:error, :already_started} -> create_game(count + 1)
          end
        end

      true ->
        {:error, :max_retries}
    end
  end
end
