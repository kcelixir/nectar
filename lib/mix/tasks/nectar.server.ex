defmodule Mix.Tasks.Nectar.Server do
  @moduledoc """
    Mix task to start Nectar
  """

  use Mix.Task

  alias MixTask.Run

  @shortdoc "Starts Nectar Server"

  @doc false
  def run(args) do
    Run.run(run_args() ++ args)
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
