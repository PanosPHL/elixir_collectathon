defmodule ElixirCollectathon.Games.Supervisor do
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathon.Games.Game, as: Game

  def create_game() do
    game_id = ElixirCollectathon.Utils.generate_code()

    if GenServer.whereis(GameServer.via_tuple(game_id)) do
      create_game()
    else
      DynamicSupervisor.start_child(__MODULE__, {GameServer, Game.new(game_id)})
    end
  end
end
