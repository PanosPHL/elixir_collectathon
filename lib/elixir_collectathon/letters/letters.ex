defmodule ElixirCollectathon.Letters do
  @letters ~w(E L I X I R)

  def get_random_letter() do
    Enum.random(@letters)
  end
end
