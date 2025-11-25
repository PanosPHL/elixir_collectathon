defmodule ElixirCollectathon.Letters do
  @letters ~w(E L I X I R)

  @doc """
  Returns a random letter from the set of available letters.

  ## Examples
      iex> letter = ElixirCollectathon.Letters.get_random_letter()
      iex> letter in ["E", "L", "I", "X", "R"]
      true
  """
  @spec get_random_letter() :: String.t()
  def get_random_letter() do
    Enum.random(@letters)
  end

  @doc """
  Returns the list of available letters.

  ## Examples
      iex> ElixirCollectathon.Letters.get_letters()
      ["E", "L", "I", "X", "I", "R"]
  """
  @spec get_letters() :: list(String.t())
  def get_letters() do
    @letters
  end
end
