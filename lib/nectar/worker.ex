defmodule Nectar.Worker do
  @moduledoc """
  Documentation for Nectar.Worker.
  """

  use GenServer

  require Logger

  alias Nectar.Request
  alias Nectar.Response

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

  defp log_request({:error, reason} = request) do
    time =
      Timex.now()
      |> Timex.format!("{ISO:Extended}")

    Logger.error(fn -> "[#{time}] - Error #{inspect(reason)}" end)

    request
  end

  defp log_request(
         %Request{
           method: method,
           path: path,
           version: {major, minor},
           headers: headers,
           body: body
         } = request
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
        {:error, "nothing received"}

      e ->
        {:error, "receive error: #{inspect(e)}"}
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
    do: write_response(%Response{status_code: 500, body: inspect(reason)}, client)

  defp write_response(%Request{} = request, client),
    do:
      write_response(
        %Response{version: request.version, status_code: 200, body: "Hello, world!"},
        client
      )

  ##
  ## 1xx - informational responses
  ##

  defp write_response(%Response{status_code: 100, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Continue"}, client)

  defp write_response(%Response{status_code: 101, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Switching Protocols"}, client)

  defp write_response(%Response{status_code: 102, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Processing"}, client)

  defp write_response(%Response{status_code: 103, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Early Hints"}, client)

  ##
  ## 2xx - success
  ##

  defp write_response(%Response{status_code: 200, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "OK"}, client)

  defp write_response(%Response{status_code: 201, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Created"}, client)

  defp write_response(%Response{status_code: 202, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Accepted"}, client)

  defp write_response(%Response{status_code: 203, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Non-Authoritative Information"}, client)

  defp write_response(%Response{status_code: 204, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "No Content"}, client)

  defp write_response(%Response{status_code: 205, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Reset Content"}, client)

  defp write_response(%Response{status_code: 206, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Partial Content"}, client)

  defp write_response(%Response{status_code: 207, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Multi-Status"}, client)

  defp write_response(%Response{status_code: 208, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Already Reported"}, client)

  defp write_response(%Response{status_code: 226, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "IM Used"}, client)

  ##
  ## 3xx - redirection
  ##

  defp write_response(%Response{status_code: 300, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Multiple Choices"}, client)

  defp write_response(%Response{status_code: 301, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Moved Permanently"}, client)

  defp write_response(%Response{status_code: 302, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Found"}, client)

  defp write_response(%Response{status_code: 303, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "See Other"}, client)

  defp write_response(%Response{status_code: 304, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Not Modified"}, client)

  defp write_response(%Response{status_code: 305, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Use Proxy"}, client)

  defp write_response(%Response{status_code: 306, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Switch Proxy"}, client)

  defp write_response(%Response{status_code: 307, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Temporary Redirect"}, client)

  defp write_response(%Response{status_code: 308, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Permanent Redirect"}, client)

  ##
  ## 4xx - client errors
  ##

  defp write_response(%Response{status_code: 400, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Bad Request"}, client)

  defp write_response(%Response{status_code: 401, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Unauthorized"}, client)

  defp write_response(%Response{status_code: 402, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Payment Required"}, client)

  defp write_response(%Response{status_code: 403, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Forbidden"}, client)

  defp write_response(%Response{status_code: 404, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Not Found"}, client)

  defp write_response(%Response{status_code: 405, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Method Not Allowed"}, client)

  defp write_response(%Response{status_code: 406, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Not Acceptable"}, client)

  defp write_response(%Response{status_code: 407, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Proxy Authentication Required"}, client)

  defp write_response(%Response{status_code: 408, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Request Timeout"}, client)

  defp write_response(%Response{status_code: 409, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Conflict"}, client)

  defp write_response(%Response{status_code: 410, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Gone"}, client)

  defp write_response(%Response{status_code: 411, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Length Required"}, client)

  defp write_response(%Response{status_code: 412, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Precondition Failed"}, client)

  defp write_response(%Response{status_code: 413, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Payload Too Large"}, client)

  defp write_response(%Response{status_code: 414, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "URI Too Long"}, client)

  defp write_response(%Response{status_code: 415, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Unsupported Media Type"}, client)

  defp write_response(%Response{status_code: 416, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Range Not Satifiable"}, client)

  defp write_response(%Response{status_code: 417, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Expectation Failed"}, client)

  defp write_response(%Response{status_code: 418, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "I'm a teapot"}, client)

  defp write_response(%Response{status_code: 421, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Misdirected Request"}, client)

  defp write_response(%Response{status_code: 422, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Unprocessable Entity"}, client)

  defp write_response(%Response{status_code: 423, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Locked"}, client)

  defp write_response(%Response{status_code: 424, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Failed Dependency"}, client)

  defp write_response(%Response{status_code: 426, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Upgrade Required"}, client)

  defp write_response(%Response{status_code: 428, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Precondition Required"}, client)

  defp write_response(%Response{status_code: 429, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Too Many Requests"}, client)

  defp write_response(%Response{status_code: 431, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Request Header Fields Too Large"}, client)

  defp write_response(%Response{status_code: 451, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Unavailable For Legal Reasons"}, client)

  ##
  ## 5xx - server errors
  ##

  defp write_response(%Response{status_code: 500, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Internal Server Error"}, client)

  defp write_response(%Response{status_code: 501, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Not Implemented"}, client)

  defp write_response(%Response{status_code: 502, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Bad Gateway"}, client)

  defp write_response(%Response{status_code: 503, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Service Unavailable"}, client)

  defp write_response(%Response{status_code: 504, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Gateway Timeout"}, client)

  defp write_response(%Response{status_code: 505, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "HTTP Version Not Supported"}, client)

  defp write_response(%Response{status_code: 506, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Variant Also Negotiates"}, client)

  defp write_response(%Response{status_code: 507, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Insufficient Storage"}, client)

  defp write_response(%Response{status_code: 508, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Loop Detected"}, client)

  defp write_response(%Response{status_code: 510, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Not Extended"}, client)

  defp write_response(%Response{status_code: 511, status_message: nil} = response, client),
    do: write_response(%{response | status_message: "Network Authentication Required"}, client)

  defp write_response(%Response{} = response, client) do
    header_lines = [
      "Content-Type: text/plain",
      "Server: #{server_version()}",
      "Content-Length: #{byte_size(response.body)}",
      "Connection: keep-alive",
      "Date: #{get_datetime()}"
    ]

    response_lines = [
      "#{get_version(response)} #{response.status_code} #{response.status_message}",
      header_lines,
      "",
      response.body
    ]

    response_lines
    |> Enum.reject(fn line -> is_nil(line) end)
    |> List.flatten()
    |> Enum.join("\r\n")
    |> send_response(client)
  end

  defp get_version(%Response{version: {major, minor}}), do: "HTTP/#{major}.#{minor}"
  defp get_version(%Response{}), do: "HTTP/1.1"

  defp server_version do
    version = Application.spec(:nectar, :vsn)
    "Nectar/#{version}"
  end

  defp log_response(response) do
    Logger.debug(fn ->
      message =
        response
        |> String.split(~r{(\r\n|\r|\n)})
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
