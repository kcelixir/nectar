defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  def start_server(retry \\ 0) do
    # https://en.wikipedia.org/wiki/Ephemeral_port#Range
    port = :rand.uniform(11848) + 49152

    case Nectar.start(nil, port: port, concurrency: 1) do
      {:ok, pid} when is_pid(pid) ->
        {:ok, port}

      _ ->
        if retry <= 5 do
          start_server(retry + 1)
        else
          {:error, :no_port}
        end
    end
  end

  setup_all do
    {:ok, port} = start_server()
    %{port: port}
  end

  test "a known good HTTP server" do
    assert {:ok, %HTTPoison.Response{}} = HTTPoison.get("http://elixir-lang.org/")
  end

  test "greets the world", %{port: port} do
    assert {:ok, %HTTPoison.Response{}} = HTTPoison.get("http://localhost:#{port}/")
  end
end
