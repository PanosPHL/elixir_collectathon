defmodule ElixirCollectathon.Entities.Hitbox do
  @type t() :: {non_neg_integer(), non_neg_integer(), pos_integer(), pos_integer()}

  @spec new({non_neg_integer(), non_neg_integer()}, pos_integer()) :: t()
  def new({x, y}, side_lw) do
    {x, y, x + side_lw, y + side_lw}
  end

  @spec new({non_neg_integer(), non_neg_integer()}, pos_integer(), pos_integer()) :: t()
  def new({x, y}, width, height) do
    {x, y, x + width, y + height}
  end
end
