defmodule ElixirCollectathon.Games.Game do
  alias __MODULE__

  @map_size {1024, 576}

  @derive Jason.Encoder
  defstruct game_id: "", tick_count: 0, is_running: true, players: %{}, next_player_num: 1

  def new(game_id) do
    %Game{game_id: game_id}
  end

  def add_player(game, player) do
    %Game{
      game
      | players: Map.put(game.players, player.name, player),
        next_player_num: game.next_player_num + 1
    }
  end

  def get_map_size() do
    @map_size
  end
end
