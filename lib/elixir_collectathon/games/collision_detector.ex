defmodule ElixirCollectathon.Games.CollisionDetector do
  def collides?({ax1, ay1, ax2, ay2}, {bx1, by1, bx2, by2}) do
    not (ax2 <= bx1 or ax1 >= bx2 or ay2 <= by1 or ay1 >= by2)
  end
end
