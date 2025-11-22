defmodule ElixirCollectathon.UtilsTest do
  use ExUnit.Case, async: true
  alias ElixirCollectathon.Utils

  describe "generate_code/0" do
    test "generates an 8-character hexadecimal string" do
      code = Utils.generate_code()

      assert String.length(code) == 8
      assert String.match?(code, ~r/^[0-9A-F]{8}$/)
    end

    test "generates unique codes on successive calls" do
      codes = for _ <- 1..100, do: Utils.generate_code()
      unique_codes = Enum.uniq(codes)

      # With cryptographically strong random bytes, all 100 should be unique
      assert length(unique_codes) == 100
    end

    test "generates codes using only uppercase hexadecimal characters" do
      code = Utils.generate_code()

      assert code == String.upcase(code)
      assert String.match?(code, ~r/^[0-9A-F]+$/)
    end
  end
end
