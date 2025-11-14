defmodule ElixirCollectathon.Players.Player do
  alias __MODULE__

  @derive Jason.Encoder
  defstruct name: "", position: {0, 0}, velocity: {0, 0}, inventory: ""

  def new(name) do
    %Player{name: name}
  end

  def set_velocity(%Player{} = player, velocity) do
    %Player{player | velocity: velocity}
  end
end
