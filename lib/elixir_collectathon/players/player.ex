defmodule ElixirCollectathon.Players.Player do
  alias ElixirCollectathon.Games.Game
  alias __MODULE__

  @player_lw 40

  @player_colors %{
    1 => "red",
    2 => "blue",
    3 => "yellow",
    4 => "green"
  }

  @derive Jason.Encoder
  defstruct color: "red", name: "", position: {0, 0}, velocity: {0, 0}, inventory: ""

  def new(name, player_num \\ 1) do
    {map_x, map_y} = Game.get_map_size()

    position =
      case player_num do
        1 -> {0, 0}
        2 -> {map_x - @player_lw, 0}
        3 -> {0, map_y - @player_lw}
        4 -> {map_x - @player_lw, map_y - @player_lw}
      end

    %Player{
      name: name,
      color: @player_colors[player_num],
      position: position
    }
  end

  def set_velocity(%Player{} = player, velocity) do
    %Player{player | velocity: velocity}
  end

  def set_position(%Player{} = player, position) do
    %Player{player | position: position}
  end
end
