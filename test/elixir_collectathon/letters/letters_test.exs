defmodule ElixirCollectathon.LettersTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Letters

  alias ElixirCollectathon.Letters

  describe "get_random_letter/0" do
    test "returns a valid letter" do
      letter = Letters.get_random_letter()

      assert letter in ["E", "L", "I", "X", "R"]
    end

    test "multiple calls can return different letters" do
      letters = Enum.map(1..10, fn _ -> Letters.get_random_letter() end)

      # With 10 random selections from 5 letters, it's very likely we get at least 2 different
      assert length(Enum.uniq(letters)) > 1
    end
  end

  describe "get_letters/0" do
    test "returns the list of available letters" do
      letters = Letters.get_letters()

      assert letters == ["E", "L", "I", "X", "I", "R"]
    end

    test "returned list has 6 elements" do
      letters = Letters.get_letters()

      assert length(letters) == 6
    end

    test "includes two I's" do
      letters = Letters.get_letters()

      assert Enum.count(letters, &(&1 == "I")) == 2
    end
  end
end
