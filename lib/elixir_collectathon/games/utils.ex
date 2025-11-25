defmodule ElixirCollectathon.Games.Utils do
  @moduledoc """
  Utility functions for the application.

  Provides helper functions used throughout the application, such as
  generating unique codes for game IDs.
  """

  @doc """
  Generates a random hexadecimal code using cryptographically strong random bytes.

  Returns an 8-character hexadecimal string (4 bytes encoded as hex).

  ## Examples

      iex> code = ElixirCollectathon.Games.Utils.generate_code()
      iex> String.length(code)
      8
      iex> String.match?(code, ~r/^[0-9A-F]{8}$/)
      true
  """
  @spec generate_code() :: String.t()
  def generate_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
  end

  @doc """
  Clamps a value between a minimum and maximum bound.

  Returns the value if it falls within the range [min, max], otherwise
  returns the nearest bound.

  ## Parameters
  - `v` - The value to clamp
  - `min` - The minimum bound (inclusive)
  - `max` - The maximum bound (inclusive)

  ## Examples
    iex> ElixirCollectathon.Games.Utils.clamp(5, 0, 10)
    5

    iex> ElixirCollectathon.Games.Utils.clamp(-5, 0, 10)
    0

    iex> ElixirCollectathon.Games.Utils.clamp(15, 0, 10)
    10
  """
  @spec clamp(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def clamp(v, min, max), do: v |> max(min) |> min(max)
end

defimpl Jason.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Jason.Encoder.encode(options)
  end
end
