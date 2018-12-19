defmodule Mix.Tasks.Maru.Routes do
  @moduledoc """
  Print routes for a `Maru.Router` module.

      $ mix maru.routes
      $ mix maru.routes MyApp.API
  """

  use Mix.Task

  def run(args) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end

    Mix.Task.run("compile", args)

    cond do
      module = List.first(args) ->
        Module.concat("Elixir", module) |> generate_module([])

      (servers = Mix.Maru.servers()) != [] ->
        for module <- servers do
          generate_module(module.__plug__, [])
        end

      true ->
        nil
    end
  end

  defp generate_module(module, prefix) do
    config = (Application.get_env(:maru, module) || [])[:versioning] || []

    adapter = Maru.Builder.Versioning.get_adapter(config[:using])

    module.__routes__
    |> Enum.sort_by(fn route -> route.version end)
    |> Enum.map(&generate_route(&1, adapter, prefix))
    |> Enum.map(&IO.puts/1)
  end

  defp generate_route(route, adapter, prefix) do
    path = adapter.path_for_params(route.path, route.version)

    format_version(route.version) <>
      format_method(route.method) <>
      format_path(prefix ++ path) <> "  " <> (route.desc[:summary] || "")
  end

  defp format_version(nil), do: "nil" |> format_version

  defp format_version(version) do
    version |> String.pad_trailing(5)
  end

  defp format_method(method) do
    method
    |> to_string()
    |> String.upcase()
    |> String.pad_trailing(7)
  end

  defp format_path([]), do: "/"

  defp format_path(p) do
    func = fn
      i when is_atom(i) -> ":#{i}"
      i -> i
    end

    ["" | p] |> Enum.map(func) |> Enum.join("/")
  end
end
