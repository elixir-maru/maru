defmodule Mix.Tasks.Maru.Routers do
  use Mix.Task

  def run(_) do
    unless System.get_env("MIX_ENV") do
      Mix.env(:dev)
    end
    for {module, _} <- Maru.Config.servers do
      :random.seed(:os.timestamp)
      all_modules =
        module
     |> traversal_module
     |> topological_sort([])
     |> Enum.reduce(%{}, fn ({module, options}, acc) ->
          generate_module(module, options, acc)
        end)

      generate(module, [], nil, all_modules)
   |> Enum.sort(fn ep1, ep2 -> ep1.version < ep2.version end)
   |> Enum.map(&generate_endpoint/1)
   |> Enum.map(&IO.puts/1)
    end
  end

  defp generate(module, mount_path, mount_version, all_modules) do
    module_endpoints =
      all_modules[module]
   |> Enum.map(&change_version(&1, mount_version))
   |> Enum.map(fn endpoint -> %{endpoint | path: mount_path ++ endpoint.path} end)

    mount_endpoints =
      Enum.map(module.__routers__, fn {_, mounted, _} ->
        m = mounted |> Keyword.fetch! :router
        resource = mounted |> Keyword.fetch! :resource
        version = mount_version || m.__version__
        generate(m, mount_path ++ resource.path, version, all_modules)
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
     |> Enum.filter(&filter_origin(&1, endpoints))
     |> Enum.filter(&filter_only(&1, only))
     |> Enum.filter(&filter_except(&1, except))

      generated |> put_in [module], endpoints ++ extended_endpoints
    end
  end

  defp change_version(endpoint, version) do
    %{endpoint | version: version || endpoint.version}
  end

  defp filter_origin(endpoint, origin_endpoints) do
    not Enum.any?(origin_endpoints, fn ep ->
      ep.method == endpoint.method and ep.path == endpoint.path
    end)
  end

  defp filter_only(_, nil), do: true
  defp filter_only(endpoint, only) do
    not Enum.any?(only, fn {method, path} ->
      method_match?(endpoint.method, method) and path_match?(endpoint.path, path)
    end)
  end

  defp filter_except(_, nil), do: true
  defp filter_except(endpoint, except) do
    Enum.any?(except, fn {method, path} ->
      method_match?(endpoint.method, method) and path_match?(endpoint.path, path)
    end)
  end

  defp method_match?(_m, :match) do
    true
  end

  defp method_match?(m1, m2) do
    m1 == m2 |> to_string |> String.upcase
  end

  defp path_match?(p1, p2) do
    lstrip(p1, p2 |> Maru.Router.Path.split)
  end

  defp lstrip([], []),                         do: true
  defp lstrip(_rest, ["*"]),                   do: true
  defp lstrip([h|t1], [h|t2]),                 do: lstrip(t1, t2)
  defp lstrip([_|t1], [h|t2]) when is_atom(h), do: lstrip(t1, t2)
  defp lstrip(_, _),                           do: false

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

  defp get_extend_opts(nil),         do: nil
  defp get_extend_opts({_, opts, _}), do: opts
end
