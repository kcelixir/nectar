defmodule Nectar.Worker do
  use GenServer

  require Logger

  def start_link(socket) do
    Task.start_link(fn ->
        {:ok, client} = :gen_tcp.accept(socket)
        Logger.debug "Client Connected"
        serve(client)
    end)
  end

  defp serve(client) do
    client
    |> read_line()
    |> write_line(client)
  end

  defp read_line(client) do
    with {:ok, data} <- :gen_tcp.recv(client, 0) do
      Logger.debug(data, label: "data")
      data
    end
  end

  defp write_line(_line, client) do
    message = "Hello, World!"

    response = """
    HTTP/1.1 200 OK
    Content-Type: text/plain
    Content-Length: #{byte_size(message)}
    Connection: close

    #{message}
    """

    :gen_tcp.send(client, response)
    :gen_tcp.shutdown(client, :read_write)
    :gen_tcp.close(client)
  end
end
