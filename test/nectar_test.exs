defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  test "greets the world" do
    assert Nectar.hello() == :world
  end
end
