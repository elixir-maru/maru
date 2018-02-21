alias Maru.Builder.Description

defmodule Description do
  defmacro __using__(_) do
    quote do
      @desc nil
      import Description.DSLs, only: [desc: 1, desc: 2]
    end
  end

  def router_struct, do: [desc: nil]

  def before_parse_router(%Macro.Env{module: module}) do
    desc = Module.get_attribute(module, :desc)
    Module.put_attribute(module, :desc, nil)

    route = Module.get_attribute(module, :router)
    Module.put_attribute(module, :router, %{route | desc: desc})
  end
end
