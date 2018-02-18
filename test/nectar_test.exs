defmodule NectarTest do
  use ExUnit.Case
  doctest Nectar

  def start_server do
    case Nectar.start(nil, concurrency: 1) do
      {:ok, pid, %{port: port}} when is_pid(pid) ->
        {:ok, port}

      {:error, reason} ->
        raise "could not start nectar server: #{inspect(reason)}"
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
