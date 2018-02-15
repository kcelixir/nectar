defmodule Nectar do
  @moduledoc """
  Documentation for Nectar.
  """

  require Logger

  def start(_type, _args) do
    listen()
  end

  def listen do
    port = 8080

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    spawn(fn ->
      serve(client)
    end)

    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)
  end

  defp read_line(socket) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      Logger.debug(data, label: "data")
      data
    end
  end

  defp write_line(_line, socket) do
    hello = """
    HTTP/1.1 200 OK

    Hello, World!
    """

    :gen_tcp.send(socket, hello)
    :gen_tcp.close(socket)
  end
end
