defmodule ElixirCollectathon.Letters.LetterTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Letters.Letter

  alias ElixirCollectathon.Letters.Letter
  alias ElixirCollectathon.Entities.Hitbox

  describe "new/2" do
    test "creates a letter with character and position" do
      letter = Letter.new("E", {10, 20})

      assert letter.char == "E"
      assert letter.position == {10, 20}
    end

    test "creates a letter at origin when position not provided" do
      letter = Letter.new("L")

      assert letter.char == "L"
      assert letter.position == {0, 0}
    end

    test "creates hitbox at letter position" do
      letter = Letter.new("I", {50, 100})

      assert letter.hitbox == Hitbox.new({50, 100}, 48)
    end

    test "creates multiple different letter types" do
      letters = ["E", "L", "I", "X", "R"]

      Enum.each(letters, fn char ->
        letter = Letter.new(char, {0, 0})
        assert letter.char == char
      end)
    end
  end

  describe "get_letter_size/0" do
    test "returns 48" do
      assert Letter.get_letter_size() == 48
    end
  end

  describe "get_padding/0" do
    test "returns 24" do
      assert Letter.get_padding() == 24
    end
  end
end
