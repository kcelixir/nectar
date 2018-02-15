defmodule Nectar.Worker do
  use GenServer

  require Logger

  def init(args) do
    {:ok, args}
  end

  def start_link(socket) do
    Task.start_link(fn ->
      {:ok, client} = :gen_tcp.accept(socket)
      Logger.debug("client connected")
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
      "" ->
        read_message_body(client, request)

      header_line when is_binary(header_line) ->
        read_header(client, %{request | headers: [header_line] ++ headers})

      other ->
        Logger.error("read_line/1 returned #{inspect(other)}")
        {:client, :error, other}
    end
  end

  defp read_message_body(client, request) do
    Logger.debug("in read_message_body/2")
    {client, request}
  end

  # FIXME: Doesn't read a line -- reads a chunk of data. Should break it up into lines.
  defp read_line(client),
    do: with({:ok, data} <- :gen_tcp.recv(client, 0), do: String.trim_trailing(data))

  defp write_response({client, :error, reason}),
    do: build_response(500, "Internal Server Error", inspect(reason)) |> send_response(client)

  defp write_response({client, _request}),
    do: build_response(200, "OK", "Hello, world!") |> send_response(client)

  defp build_response(status_code, status_message, message_body) do
    """
    HTTP/1.1 #{status_code} #{status_message}
    Content-Type: text/plain
    Server: Nectar
    Content-Length: #{byte_size(message_body)}
    Connection: close
    Date: #{get_datetime()}

    #{message_body}
    """
  end

  defp send_response(response, client) do
    :gen_tcp.send(client, response)
    :gen_tcp.shutdown(client, :read_write)
    :gen_tcp.close(client)
  end

  defp get_datetime() do
    Timex.now()
    |> Timex.format!("{WDshort} {0D} {Mshort} {YYYY} {0h12}:{m}:{s} GMT")
  end
end
