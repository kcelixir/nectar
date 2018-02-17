defmodule Nectar.Response do
  @moduledoc """
  This represents a Nectar response and contains functions that work on the Response struct.
  """

  defstruct version: nil, status_code: nil, status_message: nil, headers: [], body: nil
end
