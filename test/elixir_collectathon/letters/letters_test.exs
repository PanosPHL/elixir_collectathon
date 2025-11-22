defmodule ElixirCollectathon.LettersTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Letters

  @valid_letters ~w(E L I X I R)

  describe "get_random_letter/0" do
    test "returns a letter from the valid set" do
      letter = Letters.get_random_letter()

      assert letter in @valid_letters
    end

    test "returns different letters over multiple calls" do
      letters = for _ <- 1..100, do: Letters.get_random_letter()

      # With 100 calls, we should get at least 2 different letters
      # (extremely unlikely to get the same letter 100 times)
      unique_letters = Enum.uniq(letters)
      assert length(unique_letters) >= 2
    end

    test "only returns letters E, L, I, X, I, R" do
      letters = for _ <- 1..50, do: Letters.get_random_letter()

      Enum.each(letters, fn letter ->
        assert letter in Letters.get_letters()
      end)
    end
  end

  describe "get_letters/0" do
    test "returns the list of available letters" do
      assert Letters.get_letters() == @valid_letters
    end
  end
end
