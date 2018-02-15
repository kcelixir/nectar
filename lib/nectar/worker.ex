defmodule Nectar.Worker do
  use GenServer

  require Logger

  def init(args) do
    {:ok, args}
  end

  def start_link(socket) do
    Task.start_link(fn ->
      {:ok, client} = :gen_tcp.accept(socket)
      Logger.debug "client connected"
      serve(client)
    end)
  end

  defp serve(client) do
    client
    |> read_request()
    |> write_response()
  end

  defp read_request(client), do: read_request_line(client)

  defp read_request_line(client) do
    Logger.debug("in read_request_line/1")
    request_line = read_line(client)
    read_header(client, %{request_line: request_line, headers: []})
  end

  defp read_header(client, %{headers: headers} = request) do
    Logger.debug("in read_header/2")
    case read_line(client) do
      "" -> read_message_body(client, request)
      header_line when is_binary(header_line) -> read_header(client, %{request | headers: [header_line] ++ headers})
      other ->
        Logger.error("read_line/1 returned #{inspect other}")
        {client, :error, other}
    end
  end

  defp read_message_body(client, request) do
    Logger.debug("in read_message_body/2")
    {client, request}
  end

  # FIXME: Doesn't read a line -- reads a chunk of data. Should break it up into lines.
  defp read_line(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        trimmed = String.trim_trailing(data)
        Logger.debug(trimmed, label: "data")
        trimmed
      other ->
        other
    end
  end

  defp write_response({client, :error, reason}) do
    Logger.debug("in write_response(:error)")
    message_body = inspect reason

    response = """
    HTTP/1.1 500 Internal Server Error
    Content-Type: text/plain
    Content-Length: #{byte_size(message_body)}
    Connection: close

    #{message_body}
    """

    :gen_tcp.send(client, response)
    :gen_tcp.shutdown(client, :read_write)
    :gen_tcp.close(client)
  end

  defp write_response({client, request}) do
    Logger.debug("in write_response/1")
    message_body = "Hello, world!"

    response = """
    HTTP/1.1 200 OK
    Content-Type: text/plain
    Content-Length: #{byte_size(message_body)}
    Connection: close

    #{message_body}
    """

    :gen_tcp.send(client, response)
    :gen_tcp.shutdown(client, :read_write)
    :gen_tcp.close(client)
  end
end
