defmodule Nectar do
  @moduledoc """
  Documentation for Nectar.
  """

  require Logger

  def start(_type, _args) do
    port = 8080

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true, backlog: 1024])
    Logger.debug "Listening on Port #{port}"

    Nectar.Supervisor.start_link(socket)
  end
end
