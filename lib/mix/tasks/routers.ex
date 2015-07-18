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

  defp generate_module(mod, path, module_version) do
    for ep <- mod.__endpoints__ do
      generate_endpoint(ep, path, module_version)
    end
    mod.__routers__
    for {_, [router: m, resource: resource, version: v], _} <- mod.__routers__ do
      version = v || module_version
      generate_module(m, path ++ resource.path, version)
    end
  end

  defp generate_endpoint(ep, path, module_version) do
    # TODO: ep.param_context
    # TODO: sort by version
    version = (ep.version || module_version || "_") |> String.ljust(5)
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
