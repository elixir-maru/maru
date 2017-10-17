defmodule Maru.Builder.Params do
  @moduledoc """
  Parse and build param_content block.
  """

  alias Maru.Struct.Parameter
  alias Maru.Struct.Parameter.{Information, Runtime}
  alias Maru.Struct.{Dependent, Validator}
  alias Maru.Utils

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
      [ attr_name: unquote(attr_name),
        required:  true,
      ] |> parse |> Parameter.push
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
      [ attr_name: unquote(attr_name),
        required:  true,
        children:  children,
      ] |> Enum.concat(unquote options) |> parse |> Parameter.push
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
      [ attr_name: unquote(attr_name),
        required:  true,
      ] |> Enum.concat(unquote options) |> parse |> Parameter.push
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
      [ attr_name: unquote(attr_name),
        required: false,
      ] |> parse |> Parameter.push
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
      [ attr_name: unquote(attr_name),
        required: false,
        children: children,
      ] |> Enum.concat(unquote options) |> parse |> Parameter.push
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
      [ attr_name: unquote(attr_name),
        required: false,
      ] |> Enum.concat(unquote options) |> parse |> Parameter.push
    end
  end


  defmacro given(attr, do_block) when is_atom(attr) do
    quote do
      given([unquote(attr)], unquote(do_block))
    end
  end

  defmacro given(attrs, [do: block]) do
    Enum.all?(attrs, fn
      attr when is_atom(attr)              -> true
      {_, {:&, _, _}}                      -> true
      {_, {:fn, _, [{:->, _, [[_] | _]}]}} -> true # fun/1
      _                                    -> false
    end) || raise "error dependent format"

    depends = Enum.map(attrs, fn {param, _} -> param; param -> param end)

    validators = Enum.map(attrs, fn
      {param, func} ->
        quote do
          fn result ->
            Map.has_key?(result, unquote(param)) &&
            Map.fetch!(result, unquote(param)) |> unquote(func).()
          end
        end
      param ->
        quote do
          fn result ->
            Map.has_key?(result, unquote(param))
          end
        end
    end) |> Macro.escape

    quote do
      s = Parameter.snapshot
      Parameter.pop
      unquote(block)
      children = Parameter.pop
      Parameter.restore(s)

      children_information = Maru.Utils.get_nested(children, :information)
      children_runtime = Maru.Utils.get_nested(children, :runtime)
      validators = unquote(validators)

      %Maru.Struct.Dependent{
        information: %Dependent.Information{
          depends: unquote(depends),
          children: children_information,
        },
        runtime: quote do
          %Dependent.Runtime{
             validators: unquote(validators),
             children: unquote(children_runtime)
          }
        end
      } |> Parameter.push
    end
  end


  @doc """
  Parse params and generate Parameter struct.
  """
  def parse(options \\ []) do
    pipeline = [
      :blank_func, :attr_name, :required, :children, :type, :default, :desc, :validators
    ]
    accumulator = %{
      options:     options,
      information: %Information{},
      runtime:     quote do %Runtime{} end,
    }
    Enum.reduce(pipeline, accumulator, &do_parse/2)
  end

  defp do_parse(:blank_func, %{options: options, information: info, runtime: runtime}) do
    has_default? = options |> Keyword.has_key?(:default)
    required     = options |> Keyword.fetch!(:required)
    attr_name    = options |> Keyword.fetch!(:attr_name)
    keep_blank?  = options |> Keyword.get(:keep_blank, false)
    unpassed_func =
      case {has_default?, required} do
        {false, true} ->
          quote do
            fn _ ->
              Maru.Exceptions.InvalidFormat
              |> raise([reason: :required, param: unquote(attr_name), value: nil])
            end
          end
        {false, false} ->
          quote do
            fn x -> x end
          end
        {true, _} ->
          quote do
            fn x -> put_in(x, [unquote(attr_name)], unquote(options[:default])) end
          end
      end

    func =
      if keep_blank? do
        quote do
          fn
            {value, true, result} ->
              put_in(result, [unquote(attr_name)], value)
            {_, false, result} ->
              unquote(unpassed_func).(result)
          end
        end
      else
        quote do
          fn {_, _, result} ->
            unquote(unpassed_func).(result)
          end
        end
      end

    %{ options:     Keyword.drop(options, [:keep_blank]),
       information: info,
       runtime:     quote do
         %{ unquote(runtime) | blank_func: unquote(func) }
       end
     }
  end

  defp do_parse(:children, %{options: options, information: info, runtime: runtime}) do
    {children, options}  = Keyword.pop(options, :children, [])
    children_information = Maru.Utils.get_nested(children, :information)
    children_runtime = Maru.Utils.get_nested(children, :runtime)
    %{ options:     options,
       information: %{ info | children: children_information },
       runtime:     quote do
         Map.put(unquote(runtime), :children, unquote(children_runtime))
       end
     }
  end

  defp do_parse(key, %{options: options, information: info, runtime: runtime})
  when key in [:required, :default, :desc] do
    {value, options} = Keyword.pop(options, key)
    %{ options:     options,
       information: Map.put(info, key, value),
       runtime:     runtime,
     }
  end

  defp do_parse(:attr_name, %{options: options, information: info, runtime: runtime}) do
    attr_name = options |> Keyword.fetch!(:attr_name)
    source    = options |> Keyword.get(:source)
    options   = options |> Keyword.drop([:attr_name, :source])
    param_key = source || (attr_name |> to_string)
    %{ options:     options,
       information: %{ info | attr_name: attr_name, param_key: param_key },
       runtime:     quote do
         %{ unquote(runtime) |
            attr_name: unquote(attr_name),
            param_key: unquote(param_key),
          }
       end
    }
  end

  defp do_parse(:type, %{options: options, information: info, runtime: runtime}) do
    parsers = options |> Keyword.get(:type, :string) |> do_parse_type
    dropped =
      for {:module, _, arguments} <- parsers do
        arguments
      end |> Enum.concat
    nested =
      parsers
      |> List.last
      |> case do
        {:module, Maru.Types.Map, _}  -> :map
        {:module, Maru.Types.List, _} -> :list
        _                             -> nil
      end
    type = parse_type_info(parsers)
    func = Utils.make_parser(parsers, options)
    %{ options:     options |> Keyword.drop([:type | dropped]),
       information: %{ info | type: type },
       runtime:     quote do
         %{ unquote(runtime) |
            parser_func: unquote(func),
            nested: unquote(nested),
          }
       end
     }
  end

  defp do_parse(:validators, %{options: validators, information: info, runtime: runtime}) do
    %{attr_name: attr_name} = info
    value = quote do: value
    block =
      for {validator, option} <- validators do
        module = Utils.make_validator(validator)
        quote do
          unquote(module).validate_param!(
            unquote(attr_name),
            unquote(value),
            unquote(option)
          )
        end
      end
    %Parameter{
      information: info,
      runtime:     quote do
        %{ unquote(runtime) |
           validate_func: fn unquote(value) -> unquote_splicing(block) end
         }
      end
    }
  end


  defp do_parse_type({:fn, _, _}=func) do
    [{:func, func}]
  end
  defp do_parse_type({:&, _, _}=func) do
    [{:func, func}]
  end
  defp do_parse_type({:|>, _, [left, right]}) do
    do_parse_type(left) ++ do_parse_type(right)
  end
  defp do_parse_type({{:., _, [Access, :get]}, _, [{:__aliases__, _, [:List]}, nested]}) do
    [{:list, do_parse_type(nested)}]
  end

  defp do_parse_type(type) do
    module = Utils.make_type(type)
    [{:module, module, module.arguments}]
  end

  defp parse_type_info(parsers) do
    parsers |> Enum.reverse |> do_parse_type_info
  end
  defp do_parse_type_info([]), do: "string"
  defp do_parse_type_info([{:list, parsers} | _]) do
    {:list, parse_type_info(parsers)}
  end
  defp do_parse_type_info([{:module, module, _} | _]) do
    module |> Module.split |> List.last |> String.downcase
  end
  defp do_parse_type_info([{:func, _} | rest]) do
    do_parse_type_info(rest)
  end


  @actions [:mutually_exclusive, :exactly_one_of, :at_least_one_of, :all_or_none_of]
  for action <- @actions do
    @doc "Validator: #{action}"
    defmacro unquote(action)(:above_all) do
      action = unquote(action)
      module = Utils.make_validator(action)
      quote do
        module = unquote(module)
        attr_names =
          Parameter.snapshot
          |> Enum.filter(fn
            %Parameter{} -> true
            _ -> false end
          )
          |> Enum.map(fn
            %Parameter{information: %Information{attr_name: attr_name}} -> attr_name
          end)
        runtime = quote do
          %Validator.Runtime{
            validate_func: fn result ->
              unquote(module).validate!(unquote(attr_names), result)
            end
          }
        end
        %Validator{
          information: %Validator.Information{action: unquote(action)},
          runtime:     runtime,
        } |> Parameter.push
      end
    end

    defmacro unquote(action)(attr_names) do
      action = unquote(action)
      module = Utils.make_validator(unquote(action))
      validator =
        %Validator{
          information: %Validator.Information{action: action},
          runtime:     quote do
            %Validator.Runtime{
              validate_func: fn result ->
                unquote(module).validate!(unquote(attr_names), result)
              end
            }
          end
        } |> Macro.escape
      quote do
        Parameter.push(unquote(validator))
      end
    end
  end

end
