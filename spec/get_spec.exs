defmodule Nectar.GetSpec do
  use ESpec

  context "GET" do
    describe "/" do
      xexample do: expect HTTPoison.get("http://localhost:8081/") |> to(eq "")
    end
  end
end
