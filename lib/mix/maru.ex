defmodule Mix.Maru do
  @moduledoc false

  @doc """
  Get all maru server modules.
  """
  @spec servers :: [module()]
  def servers do
    apps =
      case Mix.Project.apps_paths() do
        nil ->
          [Mix.Project.config()[:app]]

        apps_paths ->
          Map.keys(apps_paths)
      end

    apps
    |> Enum.flat_map(&Application.get_env(&1, :maru_servers, []))
    |> Enum.uniq()
    |> case do
      [] ->
        Mix.shell().error("""
        warning: could not find Maru servers in any of the apps: #{inspect(apps)}.
        Set the servers managed by those applications in your config/config.exs:
            config #{inspect(hd(apps))}, maru_servers: [...]
        """)

        []

      repos ->
        repos
    end
  end
end
