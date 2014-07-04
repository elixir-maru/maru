defmodule Lazymaru do
  use Application

  def start(_type, _args) do
    Lazymaru.Supervisor.start_link
  end


  defp decode_params([{:__block__, _, params}]), do: params |> decode_params
  defp decode_params(params) do
    for {required, _, [param, options]} <- params do
      [ %{name: param},
        case required do
          :requires -> %{required: true}
          :optional -> %{required: false}
        end,
        case options[:type] do
          {:__aliases__, _, [type]} ->
            %{type: type |> to_string |> String.downcase}
          _ -> %{}
        end,
        case options[:regexp] do
          {:sigil_r, _, [{_, _, [reg]}, []]} -> %{regexp: reg}
          _ -> %{}
        end,
        case options[:range] do
          {:.., _, [from, to]} -> %{range: "#{from}..#{to}"}
          _ -> %{}
        end,
        case options[:default] do
          nil -> %{}
          value -> %{default: value}
        end
      ] |> Enum.reduce fn(x, y) -> Dict.merge(x, y) end
    end
  end

  def gen_docs(module) do
    for i <- module.endpoints do
      params = case i.params_block do
        nil -> %{}
        {:__block__, [], [ _ | params]} ->
          params |> decode_params
      end
      path = case i.path do
        [] -> "/"
        any -> ["" | any]
            |> Enum.map(fn p when is_atom(p) -> ":#{p}"
                           p when is_binary(p) -> p
                        end)
            |> Path.join
      end
      "METHOD: <%= method %>\nPATH: <%= path %>\n<%= for param <- params do %>PARAM: <%= param.name %>\n<% end %><%= if desc do %>DESC:<%= desc %><% end %>"
   |> EEx.eval_string([method: i.method, path: path, desc: i.desc, params: params])
    end |> Enum.join("\n\n") |> IO.puts
  end
end
