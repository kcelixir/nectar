defmodule Nectar.Request do
  @moduledoc """
  This represents a Nectar Request and contains functions that work on the Request struct.
  """

  defstruct method: nil, path: nil, version: nil, headers: [], body: nil

  def continue?(%__MODULE__{headers: headers, version: version}) do
    if Keyword.get(headers, :Connection) == "close" do
      false
    else
      case version do
        {major, minor} when major >= 1 and minor >= 1 -> true
        _ -> false
      end
    end
  end
end
