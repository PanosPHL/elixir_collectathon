defmodule ElixirCollectathon.Games.UtilsTest do
  use ExUnit.Case
  doctest ElixirCollectathon.Games.Utils

  alias ElixirCollectathon.Games.Utils

  describe "generate_code/0" do
    test "generates an 8-character hex string" do
      code = Utils.generate_code()

      assert String.length(code) == 8
    end

    test "generates uppercase hexadecimal characters" do
      code = Utils.generate_code()

      assert String.match?(code, ~r/^[0-9A-F]{8}$/)
    end

    test "generates different codes on subsequent calls" do
      code1 = Utils.generate_code()
      code2 = Utils.generate_code()

      # While theoretically they could be the same (1 in 16^8 chance),
      # it's extremely unlikely in a single test
      assert code1 != code2
    end

    test "each generated code has 4 bytes worth of entropy" do
      # Since we use :crypto.strong_rand_bytes(4) and encode to hex,
      # we get 4 * 8 = 32 bits of entropy, resulting in 8 hex characters
      code = Utils.generate_code()

      # Base.decode16 should work on the generated code
      assert {:ok, _decoded} = Base.decode16(code)
    end
  end

  describe "clamp/3" do
    test "returns value when within range" do
      assert Utils.clamp(5, 0, 10) == 5
    end

    test "returns minimum when value is below minimum" do
      assert Utils.clamp(-5, 0, 10) == 0
    end

    test "returns maximum when value is above maximum" do
      assert Utils.clamp(15, 0, 10) == 10
    end

    test "returns minimum when value equals minimum" do
      assert Utils.clamp(0, 0, 10) == 0
    end

    test "returns maximum when value equals maximum" do
      assert Utils.clamp(10, 0, 10) == 10
    end

    test "works with large numbers" do
      assert Utils.clamp(500, 0, 1000) == 500
      assert Utils.clamp(1500, 0, 1000) == 1000
    end

    test "works when min and max are equal" do
      assert Utils.clamp(5, 10, 10) == 10
      assert Utils.clamp(15, 10, 10) == 10
    end
  end
end
