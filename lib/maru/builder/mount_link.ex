defmodule Maru.Builder.MountLink do
  @name :maru_mount_link

  @doc """
  Create ets table to storage mount link.
  """
  def start do
    :ets.new(@name, [:set, :public, :named_table])
    :ok
  end

  @doc """
  Link a router module to who mounted it.
  """
  def put_father(module1, module2) do
    father =
      [ module2 |
        case :ets.lookup(@name, module1) do
          [{^module1, value}] -> value
          []                  -> []
        end
      ]
    :ets.insert(@name, {module1, father})
  end

  @doc """
  Get router module mounted on another.
  """
  def get_father(module) do
    case :ets.lookup(@name, module) do
      [{^module, value}] -> value
      []                 -> []
    end
  end

  @doc """
  Get mount link of a router module.
  """
  def get_mount_link(module, fathers) do
    do_get_mount_link(module, fathers, [module])
  end

  defp do_get_mount_link(module, fathers, result) do
    case get_father(module) do
      []             -> result |> Enum.reverse
      [father]       ->
        do_get_mount_link(father, fathers, [father | result])
      [_ | _]=linked ->
        case Enum.find(linked, fn(router) -> router in fathers end) do
          nil ->
            tested_module = Enum.at(result, -1) |> Module.split |> Enum.join(".")
            first_linked_module = List.first(linked) |> Module.split |> Enum.join(".")
            linked_module =
              Enum.map(linked, fn(module) ->
                module |> Module.split |> Enum.join(".")
              end) |> Enum.join(", ")

            raise """
            Your tested module #{tested_module} mounted to #{linked_module}.
            You must decided which branch should be used for test like this:

            use Maru.Test, for: #{first_linked_module} |> #{tested_module}
            """
          father -> do_get_mount_link(father, fathers, [father | result])
        end
    end
  end
end
