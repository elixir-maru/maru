defmodule Lazymaru.Router.Path do
  def split(path) when is_atom(path), do: [path |> to_string]
  def split(path) do
    func = fn ("", r) -> r
              (":" <> param, r) -> [param |> String.to_atom | r]
              (p, r) -> [p | r]
           end
    path |> String.split("/") |> Enum.reduce([], func) |> Enum.reverse
  end

  def pick_params(conn, path, params) do
    case do_pick(conn.private[:lazymaru_path], path, params) do
      nil -> nil
      {rest_path, params} ->
        params = params |> Dict.merge conn.private[:lazymaru_params]
        conn |> Plug.Conn.put_private(:lazymaru_path, rest_path)
             |> Plug.Conn.put_private(:lazymaru_params, params)
    end
  end

  defp do_pick(conn_path, [], params) do
    {conn_path, params}
  end
  defp do_pick([ch|ct], [rh|rt], params) when is_atom(rh) do
    params = params |> Dict.update rh, %{value: ch}, fn(param) -> %{param | value: ch} end
    do_pick(ct, rt, params)
  end
  defp do_pick([h|ct], [h|rt], params) do
    do_pick(ct, rt, params)
  end
  defp do_pick(_, _, _) do
    nil
  end
end
