defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  test "a known good HTTP server" do
    assert {:ok, %HTTPoison.Response{}} = HTTPoison.get("http://elixir-lang.org/")
  end

  test "greets the world" do
    assert {:ok, %HTTPoison.Response{}} = HTTPoison.get("http://localhost:8081/")
  end
end
