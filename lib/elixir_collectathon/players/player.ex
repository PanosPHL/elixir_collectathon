defmodule ElixirCollectathon.Players.Player do
  alias __MODULE__

  defstruct name: "", x: 0, y: 0, inventory: ""

  def new(name) do
    %Player{name: name}
  end
end
