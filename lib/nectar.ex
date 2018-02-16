defmodule Nectar do
  @moduledoc """
  Documentation for Nectar.
  """

  use Application

  require Logger

  def start(_type, args) do
    port = Keyword.get(args, :port, 8080)
    concurrency = Keyword.get(args, :concurrency, 20)

    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        backlog: 1024,
        nodelay: true
      ])

    Logger.info(fn -> "Listening on Port #{port}" end)

    Nectar.Supervisor.start_link(socket, concurrency)
  end
end
