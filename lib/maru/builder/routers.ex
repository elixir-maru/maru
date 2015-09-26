defmodule Maru.Builder.Routers do
  @moduledoc false

  @doc """
  Generate router list for `maru.routers` task and (maru_swagger)[https://hex.pm/packages/maru_swagger].

  Algorithm:
  1. Traversal modules to find all modules.
  2. Topological sort modules by module extended.
  3. Generate endpoints of sorted modules.
  4. Group modules by `version`.
  """
  def generate(module) do
    all_modules =
      module
   |> traversal_module
   |> topological_sort([])
   |> Enum.reduce(%{}, fn ({module, options}, acc) ->
        generate_module(module, options, acc)
      end)

    generate_detail(module, [], nil, all_modules)
 |> Enum.sort(fn ep1, ep2 -> ep1.version < ep2.version end)
 |> Enum.group_by(fn ep -> ep.version end)
  end

  defp generate_detail(module, mount_path, mount_version, all_modules) do
    module_endpoints =
      all_modules[module]
   |> Enum.map(&change_version(&1, mount_version))
   |> Enum.map(fn endpoint -> %{endpoint | path: mount_path ++ endpoint.path} end)

    mount_endpoints =
      Enum.map(module.__routers__, fn {_, mounted, _} ->
        m = mounted |> Keyword.fetch! :router
        resource = mounted |> Keyword.fetch! :resource
        version = mount_version || m.__version__
        generate_detail(m, mount_path ++ resource.path, version, all_modules)
      end) |> List.flatten

    module_endpoints ++ mount_endpoints
  end


  defp traversal_module(module) do
    [ {module, module.__extend__ |> get_extend_opts} |
      for {_, mounted, _} <- module.__routers__ do
        mounted |> Keyword.fetch!(:router) |> traversal_module
      end
    ] |> List.flatten
  end


  defp topological_sort([], r), do: r |> Enum.reverse
  defp topological_sort([{_, nil}=h | t], r) do
    topological_sort(t, [h | r])
  end
  defp topological_sort([{_, opts}=h | t], r) do
    depend = opts |> Keyword.fetch! :at
    t
 |> Enum.any?(fn
      {m, _} when m == depend -> true
      _                       -> false
    end)
 |> if do
      topological_sort(t ++ [h], r)
    else
      topological_sort(t, [h | r])
    end
  end

  defp generate_module(module, options, generated) do
    endpoints = module.__endpoints__

    if is_nil(options) or is_nil(Keyword.get options, :extend) do
      generated |> put_in [module], endpoints
    else
      extended_module = options |> Keyword.fetch! :at
      extended_endpoints = generated[extended_module]
      only = options |> Keyword.get :only, nil
      except = options |> Keyword.get :except, nil

      extended_endpoints =
        extended_endpoints
     |> Enum.map(&change_version(&1, options[:version]))
     |> Enum.filter(&Maru.Plugs.Extend.filter_origin(&1, endpoints))
     |> Enum.filter(&Maru.Plugs.Extend.filter_only(&1, only))
     |> Enum.filter(&Maru.Plugs.Extend.filter_except(&1, except))

      generated |> put_in [module], endpoints ++ extended_endpoints
    end
  end

  defp change_version(endpoint, version) do
    %{endpoint | version: version || endpoint.version}
  end

  defp get_extend_opts(nil),         do: nil
  defp get_extend_opts({_, opts, _}), do: opts
end
