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
    |> write_response(client)
  end

  defp read_request(client) do
    with {:ok, raw_request} <- :gen_tcp.recv(client, 0) do
      request = parse_request(raw_request)

      Logger.debug(inspect(request), label: "request")
      request
    end
  end

  defp parse_request(data) do
    [request_line | rest] = String.split(data, "\r\n")

    {headers, body} = parse_headers(rest)

    %{request_line: request_line, headers: headers, body: body}
  end

  defp parse_headers(["" | t]), do: {[], t}

  defp parse_headers([h | t]) do
    [key, value] = String.split(h, ":", parts: 2, trim: true)

    case parse_headers(t) do
      {headers, body} when is_binary(body) -> {[{key, value}] ++ headers, body}
      {headers, _} -> {[{key, value}] ++ headers, nil}
    end
  end

  defp write_response({:error, reason}, client),
    do: build_response(500, "Internal Server Error", inspect(reason)) |> send_response(client)

  defp write_response(%{request_line: _, headers: _, body: _}, client),
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
    |> String.trim()
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
