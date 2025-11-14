defmodule ElixirCollectathon.Games.Game do
  alias __MODULE__

  @derive Jason.Encoder
  defstruct game_id: "", tick_count: 0, is_running: true, players: %{}

  def new(game_id) do
    %Game{game_id: game_id}
  end
end
