defmodule Nectar.Supervisor do
  use Supervisor

  def start_link(socket) do
    Supervisor.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def init(socket) do
    children =
      (0..20)
      |> Enum.map(fn (n) ->
        worker(Nectar.Worker, [socket], restart: :permanent, id: :"worker#{n}")
      end)

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 100_000_000, max_seconds: 1)
  end
end
