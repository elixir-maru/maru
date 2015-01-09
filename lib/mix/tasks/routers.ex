defmodule Mix.Tasks.Maru.Routers do
  use Mix.Task

  def run(_) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end
    for {mod, _} <- Maru.Config.servers do
      generate_module(mod, [], nil)
    end
  end

  defp generate_module(mod, path, version) do
    version = version || mod.__version__
    for ep <- mod.__endpoints__ do
      generate_endpoint(ep, path, version)
    end
    for {_, [router: m, resource: resource], _} <- mod.__routers__ do
      generate_module(m, path ++ resource.path, version)
    end
  end

  defp generate_endpoint(ep, path, version) do
    version = String.ljust(version, 5)
    method = String.ljust(ep.method, 7)
    path = generate_path(path ++ ep.path)
    desc = ep.desc
    IO.puts "#{version} #{method} #{path}    #{desc}"
  end

  defp generate_path([]), do: "/"
  defp generate_path(p) do
    func = fn(i) when is_atom(i) -> ":#{i}"
             (i) -> i
    end
    ["" | p] |> Enum.map(func) |> Enum.join("/")
  end
end
