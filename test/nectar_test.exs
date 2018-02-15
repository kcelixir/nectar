defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  test "greets the world" do
    assert HTTPoison.get("http://localhost:8081/") == ""
  end
end
