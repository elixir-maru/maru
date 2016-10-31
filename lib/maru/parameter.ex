defmodule Maru.Parameter.Phoenix do
  @moduledoc """
  Bring maru's params parser to Phoenix, just use it as the same as maru.
  Look at maru's documents for more details.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      require Maru.Struct.Parameter
      import Maru.Builder.DSLs, only: [helpers: 1, params: 1, params: 2]

      Module.register_attribute __MODULE__, :parameter_functions, accumulate: true

      @parameters []
      @group []
      @on_definition unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  def __on_definition__(%Macro.Env{module: module}, :def, name, [_, _], guards, _body) do
    Module.get_attribute(module, :parameters)
    |> Enum.map(fn p -> p.runtime end)
    |> case do
      [] -> :ok
      parameters_runtime ->
        guards = [] == guards || guards
        Module.put_attribute(module, :parameter_functions, {name, guards, parameters_runtime})
        Module.put_attribute(module, :parameters, [])
    end
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}) do
    module
    |> Module.get_attribute(:parameter_functions)
    |> Enum.map(fn {name, guards, runtime} ->
      quote do
        defoverridable [{unquote(name), 2}]
        def unquote(name)(conn, params) when unquote(guards) do
          super(conn, Maru.Runtime.parse_params(
            unquote(runtime), %{}, params
          ))
        end
      end
    end)
  end

end
