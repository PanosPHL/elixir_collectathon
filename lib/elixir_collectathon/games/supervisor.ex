defmodule ElixirCollectathon.Games.Supervisor do
  alias ElixirCollectathon.Games.Server, as: GameServer

  def create_game() do
    game_id = ElixirCollectathon.Utils.generate_code()

    if GenServer.whereis(GameServer.via_tuple(game_id)) do
      create_game()
    else
      case DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id}) do
        {:ok, _server_pid} -> {:ok, game_id}
        {:error, :already_started} -> create_game()
      end
    end
  end
end
