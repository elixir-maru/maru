defmodule Maru.Builder.Params do
  @moduledoc """
  Parse and build param_content block.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Validator

  @doc false
  defmacro use(param) when is_atom(param) do
    quote do
      params = @shared_params[unquote(param)]
      Module.eval_quoted __MODULE__, params, [], __ENV__
    end
  end

  defmacro use(params) do
    quote do
      for i <- unquote(params) do
        params = @shared_params[i]
        Module.eval_quoted __MODULE__, params, [], __ENV__
      end
    end
  end

  @doc """
  Define a param should be present.
  """
  defmacro requires(attr_name) do
    quote do
      Parameter.push(%{
        parse_options |
        attr_name: unquote(attr_name),
        required: true,
        children: [],
      })
    end
  end

  defmacro requires(attr_name, options, [do: block]) do
    options = Keyword.merge([type: :list], options) |> Macro.escape
    quote do
      s = Parameter.snapshot
      Parameter.pop
      unquote(block)
      children = Parameter.pop
      Parameter.restore(s)
      Parameter.push(%{
        parse_options(unquote options) |
        attr_name: unquote(attr_name),
        required: true,
        children: children,
      })
    end
  end

  defmacro requires(attr_name, [do: _]=block) do
    quote do
      requires(unquote(attr_name), [type: :list], unquote(block))
    end
  end

  defmacro requires(attr_name, options) do
    options = options |> Macro.escape
    quote do
      Parameter.push(%{
        parse_options(unquote options) |
        attr_name: unquote(attr_name),
        required: true,
        children: [],
      })
    end
  end


  @doc """
  Define a params group.
  """
  defmacro group(group_name, options \\ [], block) do
    quote do
      requires(unquote(group_name), unquote(options), unquote(block))
    end
  end


  @doc """
  Define a param should be present or not.
  """
  defmacro optional(attr_name) do
    quote do
      Parameter.push(%{
        parse_options |
        attr_name: unquote(attr_name),
        required: false,
        children: [],
      })
    end
  end

  defmacro optional(attr_name, options, [do: block]) do
    options = Keyword.merge([type: :list], options) |> Macro.escape
    quote do
      s = Parameter.snapshot
      Parameter.pop
      unquote(block)
      children = Parameter.pop
      Parameter.restore(s)
      Parameter.push(%{
        parse_options(unquote options) |
        attr_name: unquote(attr_name),
        required: false,
        children: children,
      })
    end
  end


  defmacro optional(attr_name, [do: _]=block) do
    quote do
      optional(unquote(attr_name), [type: :list], unquote(block))
    end
  end

  defmacro optional(attr_name, options) do
    options = options |> Macro.escape
    quote do
      Parameter.push(%{
        parse_options(unquote options) |
        attr_name: unquote(attr_name),
        required: false,
        children: [],
      })
    end
  end


  def parse_options(options \\ []) do
    {rest, parameter} = [
      :type, :coercer, :default, :desc, :source
    ] |> Enum.reduce({options, %Parameter{}}, &do_parse_option/2)
    validators =
      for {validator, option} <- rest do
        { try do
            [ Maru.Validations,
              validator |> Atom.to_string |> Maru.Utils.upper_camel_case
            ] |> Module.safe_concat
          rescue
            ArgumentError ->
              Maru.Exceptions.UndefinedValidator |> raise([param: "attr_name", validator: validator])
          end,
          option
        }
      end
    %{ parameter | validators: validators }
  end

  defp do_parse_option(:type, {options, result}) do
    { options |> Keyword.drop([:type]),
      %{ result | type: [
           Maru.Coercions |
           options
           |> Keyword.get(:type, :string)
           |> case do
              {:__aliases__, _, t} -> t
              t when is_atom(t)    ->
                [ t |> Atom.to_string |> Maru.Utils.upper_camel_case ]
           end,
         ] |> Module.safe_concat,
      }
    }
  end

  defp do_parse_option(:coercer, {options, result}) do
    coercer =
      case options[:coerce_with] do
        nil                  -> {:module, result.type}
        {:__aliases__, _, m} -> {:module, Module.safe_concat([Maru.Coercions | m])}
        {:fn, _, _}=c        -> {:func, c}
        {:&, _, _}=c         -> {:func, c}
        _                    -> raise "unknown coercer format"
      end

    { options, coercer_argument } =
      case coercer do
        {:module, module} ->
          Enum.reduce(module.arguments, {options, %{}}, fn key, {options, args} ->
            { Keyword.drop(options, key),
              put_in(args, [key], options[key]),
            }
          end)
        {:func, _} ->
          {options, nil}
      end
    { options |> Keyword.drop([:coerce_with]),
      %{ result |
         coercer: coercer,
         coercer_argument: Macro.escape(coercer_argument),
      }
    }
  end

  defp do_parse_option(key, {options, result}) when key in [:default, :desc, :source] do
    { Keyword.drop(options, [key]),
      Map.put(result, key, options[key]),
    }
  end


  @actions [:mutually_exclusive, :exactly_one_of, :at_least_one_of]
  for action <- @actions do
    @doc "Validator: #{action}"
    defmacro unquote(action)(:above_all) do
      action = unquote(action)
      quote do
        attr_names =
          for %Parameter{attr_name: attr_name} <- Parameter.snapshot do
            attr_name
          end
        unquote(action)(attr_names)
      end
    end

    defmacro unquote(action)(attr_names) do
      validator =
        try do
          [ Maru.Validations,
            unquote(action) |> Atom.to_string |> Maru.Utils.upper_camel_case
          ] |> Module.safe_concat
        rescue
          ArgumentError ->
            Maru.Exceptions.UndefinedValidator |> raise([param: attr_names, validator: unquote(action)])
        end
      quote do
        Parameter.push(%Validator{
          validator: unquote(validator),
          attr_names: unquote(attr_names),
        })
      end
    end
  end

end
