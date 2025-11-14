defmodule ElixirCollectathon.Utils do
  def generate_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
  end
end

defimpl Jason.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Jason.Encoder.encode(options)
  end
end
