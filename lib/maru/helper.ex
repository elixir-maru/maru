defmodule Maru.Helper do
  defmacro __using__(_) do
    quote do
      import Maru.Helpers.Params
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    shared_params = for {name, params} <- Module.get_attribute(module, :shared_params) do
      {name, params |> Macro.escape}
    end
    quote do
      def __shared_params__ do
        unquote(shared_params)
      end
    end
  end
end
