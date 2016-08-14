defmodule Maru.Utils do
  @moduledoc false

  @doc false
  def upper_camel_case(s) do
    s |> String.split("_") |> Enum.map(
      fn i -> i |> String.capitalize end
    ) |> Enum.join("")
  end

  @doc false
  def lower_underscore(s) do
    for << i <- s >> , into: "" do
      if i in ?A..?Z do
        <<?\s, i + 32>>
      else
        <<i>>
      end
    end |> String.split |> Enum.join("_")
  end

  @doc false
  def make_validator(validator) do
    try do
      module = [
        Maru.Validations,
        validator |> Atom.to_string |> upper_camel_case
      ] |> Module.concat
      module.__info__(:functions)
      module
    rescue
      UndefinedFunctionError ->
        Maru.Exceptions.UndefinedValidator
        |> raise([validator: validator])
    end
  end

  @doc false
  def make_type({:__aliases__, _, type}) do
    do_make_type(type)
  end

  def make_type(type) when is_atom(type) do
    type = type |> Atom.to_string |> upper_camel_case
    do_make_type([type])
  end

  defp do_make_type(type) do
    try do
      module = [ Maru.Types | type ] |> Module.concat
      module.__info__(:functions)
      module
    rescue
      UndefinedFunctionError ->
        type = type |> Module.concat |> inspect
        Maru.Exceptions.UndefinedType |> raise([type: type])
    end
  end

  @doc false
  def make_parser(parsers, options) do
    value = quote do: value
    block =
      Enum.reduce(parsers, value, fn
        {:func, func}, ast ->
          quote do
            unquote(func).(unquote(ast))
          end
        {:module, module, arguments}, ast ->
          arguments =
            Keyword.take(options, arguments)
            |> Enum.into(%{})
            |> Macro.escape
          quote do
            unquote(module).parse(unquote(ast), unquote(arguments))
          end
        {:list, nested}, ast ->
          func = make_parser(nested, options)
          quote do
            Enum.map(unquote(ast), unquote(func))
          end
      end)
    quote do
      fn unquote(value) -> unquote(block) end
    end
  end

end
