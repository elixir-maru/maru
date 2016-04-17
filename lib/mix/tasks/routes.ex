defmodule Mix.Tasks.Maru.Routes do
  @mdouledoc """
  Print routes for a `Maru.Router` module.

      $ mix maru.routes
      $ mix maru.routes MyApp.API
  """

  use Mix.Task

  def run(args) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end
    Mix.Task.run "compile", args

    cond do
      module = List.first(args) ->
        Module.concat("Elixir", module) |> generate_module([])

      (servers = Application.get_all_env(:maru)) != [] ->
        for {module, _} <- servers do
          generate_module(module, [])
        end

      Code.ensure_loaded?(Phoenix) ->
        phoenix_module = Module.concat(Mix.Phoenix.base(), "Router")
        for %{
          __struct__: Phoenix.Router.Route,
          kind: :forward,
          path: path,
          plug: module,
        } <- phoenix_module.__routes__ do
          try do
            prefix = path |> String.split("/", trim: true)
            generate_module(module, prefix)
          rescue
            UndefinedFunctionError -> nil
          end
        end

      true -> nil
    end
  end

  defp generate_module(module, prefix) do
    config = (Application.get_env(:maru, module) || [])[:versioning] || []

    adapter = Maru.Builder.Versioning.get_adapter(config[:using])

    module.__endpoints__
    |> Enum.sort_by(fn ep -> ep.version end)
    |> Enum.map(&generate_endpoint(&1, adapter, prefix))
    |> Enum.map(&IO.puts/1)
  end

  defp generate_endpoint(ep, adapter, prefix) do
    path = adapter.path_for_params(ep.path, ep.version)
    format_version(ep.version) <>
    format_method(ep.method) <>
    format_path(prefix ++ path) <>
    "  " <> (ep.desc || "")
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
