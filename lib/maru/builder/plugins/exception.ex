alias Maru.Builder.Plugins.Exception
alias Maru.Builder.Exception.RETURN

defmodule Exception do
  defstruct errors:    nil,
            error_var: nil,
            function:  nil,
            block:     nil

  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :exceptions, accumulate: true
      import Exception.DSLs
    end
  end

  def route_struct, do: [mount_link: []]

  def callback_mount(%{mount_link: mount_link}=mounted_route, module, _env) do
    %{mounted_route | mount_link: mount_link ++ [module]}
  end

  def callback_route(route, _env) do
    route.mount_link
    |> Enum.filter(fn module ->
      if Module.open?(module) do
        Module.get_attribute(module, :exceptions) != []
      else
        {:__error_handler__, 1} in module.__info__(:functions)
      end
    end)
    |> Enum.map(fn module ->
      {module, :__error_handler__}
    end)
  end

  def callback_plug_router(%Macro.Env{module: module}) do
    module
    |> Module.get_attribute(:exceptions)
    |> Enum.empty?
    && []
    || [{module, :__error_handler__}]
  end

  def callback_before_compile(%Macro.Env{module: module}=env) do
    rescue_block =
      Module.get_attribute(module, :exceptions)
      |> Enum.reverse
      |> Enum.map(&Exception.Helper.make_rescue_block/1)
      |> List.flatten

    [] == rescue_block && raise RETURN

    quoted = quote do
      def __error_handler__(func) do
        fn ->
          try do
            func.()
          rescue
          unquote(rescue_block)
          end
        end
      end
    end

    Module.eval_quoted(env, quoted)
  rescue
    RETURN -> nil
  end

end
