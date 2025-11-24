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
  def generate_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
  end

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
