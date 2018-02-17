defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  # https://en.wikipedia.org/wiki/Ephemeral_port#Range
  def start_server, do: start_server(49152)

  def start_server(65536), do: {:error, :no_port}

  def start_server(port) do
    case Nectar.start(nil, port: port, concurrency: 1) do
      {:ok, pid} when is_pid(pid) ->
        {:ok, port}

      _ ->
        start_server(port + 1)
    end
  end

  setup_all do
    {:ok, port} = start_server()
    %{port: port}
  end

  test "GET /", %{port: port} do
    assert {:ok, %HTTPoison.Response{} = response} = HTTPoison.get("http://localhost:#{port}/")
    assert response.status_code == 200
    assert response.body == "Hello, world!"
    assert Enum.any?(response.headers, fn header -> header == {"Content-Type", "text/plain"} end)
  end
end
