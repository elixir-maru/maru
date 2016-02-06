defmodule Mix.Tasks.Maru.Routers do
  use Mix.Task

  def run(args) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end
    Mix.Task.run "compile", args
    IO.puts :stderr, "maru.routers is deprecated in favor of maru.routes"
    for {module, _} <- Maru.Config.servers do
      module
   |> Maru.Builder.Routers.generate
   |> Map.values
   |> List.flatten
   |> Enum.map(&generate_endpoint/1)
   |> Enum.map(&IO.puts/1)
    end
  end

  defp generate_endpoint(ep) do
    "#{ep.version |> format_version}#{ep.method |> format_method}#{ep.path |> format_path}  #{ep.desc}"
  end

  defp format_version(nil), do: "nil" |> format_version
  defp format_version(version) do
    version |> String.ljust(5)
  end

  defp format_method({:_, [], nil}), do: ":match" |> format_method
  defp format_method(method) do
    method |> String.ljust(7)
  end

  defp format_path([]), do: "/"
  defp format_path(p) do
    func = fn
      i when is_atom(i) -> ":#{i}"
      i                 -> i
    end
    ["" | p] |> Enum.map(func) |> Enum.join("/")
  end
end
