defmodule ElixirCollectathon.Games.Supervisor do
  alias ElixirCollectathon.Games.Server, as: GameServer

  def create_game(count \\ 0) do
    game_id = ElixirCollectathon.Utils.generate_code()

    cond do
      count <= 5 ->
        if GenServer.whereis(GameServer.via_tuple(game_id)) do
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
