defmodule Nectar.Worker do
  @moduledoc """
  Documentation for Nectar.Worker.
  """

  use GenServer

  alias Nectar.Request

  require Logger

  def init(args) do
    {:ok, args}
  end

  def start_link(socket) do
    Task.start_link(fn ->
      {:ok, client} = :gen_tcp.accept(socket)
      Logger.debug("client connected")
      :ok = :inet.setopts(client, packet: :http_bin)
      serve(client)
    end)
  end

  defp serve(client) do
    with {method, path, version} <- read_request(client),
         headers <- read_headers(client),
         body <- "" do
      request = %Request{
        method: method,
        path: path,
        version: version,
        headers: headers,
        body: body
      }

      request
      |> log_request()
      |> write_response(client)

      if Request.continue?(request) do
        serve(client)
      end
    else
      {:error, :closed} ->
        # Don't handle another request (let the Task die)
        nil

      {:error, :enotconn} ->
        # Don't handle another request (let the Task die)
        nil

      {:error, reason} ->
        {:error, reason}
        |> log_request()
        |> write_response(client)

        serve(client)
    end
  end

  defp log_request(request = {:error, reason}) do
    time =
      Timex.now()
      |> Timex.format!("{ISO:Extended}")

    Logger.error(fn -> "[#{time}] - Error #{inspect(reason)}" end)

    request
  end

  defp log_request(
         request = %Request{
           method: method,
           path: path,
           version: {major, minor},
           headers: headers,
           body: body
         }
       ) do
    Logger.info(fn ->
      time = Timex.format!(Timex.now(), "{ISO:Extended}")
      "[#{time}] - HTTP/#{major}.#{minor}: #{method} #{inspect(path)}"
    end)

    Logger.debug(fn ->
      body =
        case String.split(body, ~r{(\r\n\|\r|\n)}) do
          [""] -> []
          list -> list
        end

      message =
        [
          "#{method} #{inspect(path)} HTTP/#{major}.#{minor}",
          Enum.map(headers, fn {k, v} -> "#{k}: #{v}" end),
          "",
          body
        ]
        |> List.flatten()
        |> Enum.map(fn line -> "< " <> line end)
        |> Enum.join("\n")

      "\n<\n" <> message
    end)

    request
  end

  defp read_request(client) do
    with {:ok, {:http_request, method, path, version}} <- :gen_tcp.recv(client, 0) do
      {method, path, version}
    else
      {:http_error, error} ->
        {:error, error}

      # The client closed the connection
      {:error, :enotconn} ->
        {:error, :enotconn}

      # The client closed the connection
      {:error, :closed} ->
        {:error, :closed}

      nil ->
        {:error, "Nothing Received"}

      e ->
        {:error, "Receive Error: #{inspect(e)}"}
    end
  end

  defp read_headers(client) do
    read_headers([], client)
  end

  defp read_headers(acc, client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, {:http_header, _, name, _, value}} ->
        [{name, value} | acc]
        |> read_headers(client)

      {:ok, :http_eoh} ->
        acc

      unknown ->
        Logger.warn(unknown, label: "unknown in headers")
        acc
    end
  end

  defp write_response({:error, reason}, client),
    do: build_response(500, "Internal Server Error", inspect(reason)) |> send_response(client)

  defp write_response(%Request{}, client),
    do: build_response(200, "OK", "Hello, world!") |> send_response(client)

  defp build_response(status_code, status_message, message_body) do
    # account for the "\r\n" pair at the end of the message body
    content_length = byte_size(message_body) + 2

    """
    HTTP/1.1 #{status_code} #{status_message}
    Content-Type: text/plain
    Server: Nectar
    Content-Length: #{content_length}
    Connection: keep-alive
    Date: #{get_datetime()}

    #{message_body}\r
    """
  end

  defp log_response(response) do
    Logger.debug(fn ->
      message =
        response
        |> String.split(~r{(\r\n\|\r|\n)})
        |> Enum.map(fn line -> "> " <> line end)
        |> Enum.join("\n")

      "\n>\n" <> message
    end)

    response
  end

  defp send_response(response, client) do
    log_response(response)
    :gen_tcp.send(client, response)
  end

  defp get_datetime do
    Timex.now()
    |> Timex.format!("{WDshort} {0D} {Mshort} {YYYY} {0h12}:{m}:{s} GMT")
  end
end
