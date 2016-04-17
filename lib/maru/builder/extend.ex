defmodule Maru.Builder.Extend do
  @moduledoc false

  @doc """
  Take endpoints by an extended module.
  """
  def take_extended(_, nil), do: []
  def take_extended(eps_new, {v_new, opts}) do
    module  = opts |> Keyword.fetch!(:at)
    v_old   = opts |> Keyword.fetch!(:extend)
    only    = opts |> Keyword.get(:only, nil)
    except  = opts |> Keyword.get(:except, nil)
    'Elixir.' ++ _ = Atom.to_char_list module
    unless is_nil(only) or is_nil(except) do
      raise ":only and :except are in conflict!"
    end

    module.__endpoints__
    |> Enum.filter(fn ep ->
      (ep.version == v_old) and getable?(eps_new, ep)
    end)
    |> Enum.filter(func(only, except))
    |> Enum.map(fn ep ->
      %{ep | version: v_new}
    end)
  end

  defp func(nil, nil),    do: fn _  -> true end
  defp func(only, nil),   do: fn ep -> ep_match?(only, ep) end
  defp func(nil, except), do: fn ep -> not ep_match?(except, ep) end


  defp getable?(eps_new, ep) do
    Enum.all?(eps_new, fn ep_new ->
      ep_new.method != ep.method or do_getable?(ep_new.path, ep.path)
    end)
  end

  defp do_getable?([], []),           do: false
  defp do_getable?([h1|_], [h2|_])
  when is_binary(h1) and is_atom(h2), do: true
  defp do_getable?([h|t1], [h|t2]),   do: do_getable?(t1, t2)
  defp do_getable?(_, _),             do: true


  defp ep_match?(conds, ep) do
    Enum.any?(conds, fn {method, path} ->
      path = Maru.Builder.Path.split(path)
      method_match?(ep.method, method) and path_match?(ep.path, path)
    end)
  end

  defp method_match?(_m, :match), do: true
  defp method_match?(m1, m2) do
    m1 == m2 |> to_string |> String.upcase
  end

  defp path_match?([{:version}|t1], t2),            do: path_match?(t1, t2)
  defp path_match?([], []),                         do: true
  defp path_match?(_rest, ["*"]),                   do: true
  defp path_match?([h|t1], [h|t2]),                 do: path_match?(t1, t2)
  defp path_match?([_|t1], [h|t2]) when is_atom(h), do: path_match?(t1, t2)
  defp path_match?(_, _),                           do: false

end
