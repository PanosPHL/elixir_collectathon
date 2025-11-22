defmodule ElixirCollectathon.Letters.LetterTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Letters
  alias ElixirCollectathon.Letters.Letter

  describe "new/2" do
    test "creates a letter with character and position" do
      letter = Letter.new("E", {100, 200})

      assert letter.char == "E"
      assert letter.position == {100, 200}
    end

    test "creates a letter with default position {0, 0}" do
      letter = Letter.new("L")

      assert letter.char == "L"
      assert letter.position == {0, 0}
    end

    test "creates letters for all valid characters" do
      valid_chars = Letters.get_letters()

      Enum.each(valid_chars, fn char ->
        letter = Letter.new(char, {50, 50})
        assert letter.char == char
        assert letter.position == {50, 50}
      end)
    end
  end

  describe "get_letter_size/0" do
    test "returns the letter size constant" do
      assert Letter.get_letter_size() == 48
    end

    test "letter size is a positive integer" do
      size = Letter.get_letter_size()

      assert is_integer(size)
      assert size > 0
    end
  end

  describe "get_padding/0" do
    test "returns the padding constant" do
      assert Letter.get_padding() == 24
    end

    test "padding is a positive integer" do
      padding = Letter.get_padding()

      assert is_integer(padding)
      assert padding > 0
    end
  end
end
