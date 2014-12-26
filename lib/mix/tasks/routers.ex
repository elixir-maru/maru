defmodule Mix.Tasks.Lazymaru.Routers do
  use Mix.Task

  def run(_) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end
    for {mod, _} <- Lazymaru.Config.servers do
      mod |> generate_module
    end
  end

  defp generate_module(mod, path \\ []) do
    for ep <- mod.__endpoints__ do
      generate_endpoint(ep, path)
    end
    for {_, [router: m, resource: resource], _} <- mod.__routers__ do
      generate_module(m, path ++ resource.path)
    end
  end

  defp generate_endpoint(ep, path) do
    method = String.ljust(ep.method, 7)
    path = generate_path(path ++ ep.path)
    desc = ep.desc
    IO.puts "#{method} #{path}    #{desc}"
  end

  defp generate_path([]), do: "/"
  defp generate_path(p) do
    func = fn(i) when is_atom(i) -> ":#{i}"
             (i) -> i
    end
    ["" | p] |> Enum.map(func) |> Enum.join("/")
  end
end
