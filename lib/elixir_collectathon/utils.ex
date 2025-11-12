defmodule ElixirCollectathon.Utils do
  def generate_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
  end
end
