defmodule Nectar do
  @moduledoc """
  Documentation for Nectar.
  """

  use Application

  require Logger

  def start(_type, args) do
    requested_port = Keyword.get(args, :port, 0)
    concurrency = Keyword.get(args, :concurrency, 20)

    {:ok, socket} =
      :gen_tcp.listen(requested_port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        backlog: 1024,
        nodelay: true
      ])

    {:ok, assigned_port} = :inet.port(socket)
    Logger.info(fn -> "listening on port #{assigned_port}" end)

    case Nectar.Supervisor.start_link(socket, concurrency) do
      {:ok, pid} -> {:ok, pid, %{port: assigned_port}}
      {:error, _reason} = other -> other
    end
  end
end
