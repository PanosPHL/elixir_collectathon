defmodule ElixirCollectathon.UtilsTest do
  use ExUnit.Case, async: true
  doctest ElixirCollectathon.Utils
  alias ElixirCollectathon.Utils

  describe "generate_code/0" do
    test "generates a code string" do
      code = Utils.generate_code()

      assert is_binary(code)
      assert String.length(code) == 8
    end

    test "generates different codes on each call" do
      code1 = Utils.generate_code()
      code2 = Utils.generate_code()
      code3 = Utils.generate_code()

      assert code1 != code2
      assert code2 != code3
      assert code1 != code3
    end

    test "generates hexadecimal codes" do
      code = Utils.generate_code()

      assert String.match?(code, ~r/^[0-9A-F]{8}$/)
    end
  end

  describe "Jason.Encoder for Tuple" do
    test "encodes tuples as lists" do
      tuple = {1, 2, 3}
      encoded = Jason.encode!(tuple)

      assert encoded == "[1,2,3]"
    end

    test "encodes position tuples" do
      position = {100, 200}
      encoded = Jason.encode!(position)

      assert encoded == "[100,200]"
    end

    test "encodes velocity tuples" do
      velocity = {0.5, -0.5}
      encoded = Jason.encode!(velocity)

      assert encoded == "[0.5,-0.5]"
    end

    test "encodes nested structures with tuples" do
      data = %{
        position: {10, 20},
        velocity: {1.0, -1.0}
      }

      encoded = Jason.encode!(data)
      decoded = Jason.decode!(encoded)

      assert decoded["position"] == [10, 20]
      assert decoded["velocity"] == [1.0, -1.0]
    end
  end
end
