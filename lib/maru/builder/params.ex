defmodule Maru.Builder.Params do
  @moduledoc """
  Parse and build param_content block.
  """

  alias Maru.Router.Param
  alias Maru.Router.Validator

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
    param(attr_name, [], [required: true, nested: false])
  end

  defmacro requires(attr_name, options, [do: block]) do
    [ param(attr_name, Dict.merge([type: :list], options), [required: true, nested: false]),
      quote do
        group = @group
        @group group ++ [unquote(attr_name)]
        unquote(block)
        @group group
      end
    ]
  end

  defmacro requires(attr_name, [do: block]) do
    [ param(attr_name, [type: :list], [required: true, nested: true]),
      quote do
        group = @group
        @group group ++ [unquote(attr_name)]
        unquote(block)
        @group group
      end
    ]
  end

  defmacro requires(attr_name, options) do
    param(attr_name, options, [required: true, nested: false])
  end


  @doc """
  Define a params group.
  """
  defmacro group(group_name, options \\ [], [do: block]) do
    [ param(group_name, Dict.merge([type: :list], options), [required: true, nested: true]),
      quote do
        group = @group
        @group group ++ [unquote group_name]
        unquote(block)
        @group group
      end
    ]
  end

  @doc """
  Define a param should be present or not.
  """
  defmacro optional(attr_name) do
    param(attr_name, [], [required: false, nested: false])
  end

  defmacro optional(attr_name, options, [do: block]) do
    [ param(attr_name, Dict.merge([type: :list], options), [required: false, nested: true]),
      quote do
        group = @group
        @group group ++ [unquote(attr_name)]
        unquote(block)
        @group group
      end
    ]
  end

  defmacro optional(attr_name, [do: block]) do
    [ param(attr_name, [type: :list], [required: false, nested: true]),
      quote do
        group = @group
        @group group ++ [unquote(attr_name)]
        unquote(block)
        @group group
      end
    ]
  end

  defmacro optional(attr_name, options) do
    param(attr_name, options, [required: false, nested: false])
  end


  defp param(attr_name, options, [required: required, nested: nested]) do
    parser =
      case options[:type] do
        nil -> nil
        {:__aliases__, _, [t]} -> [Maru.ParamType, t] |> Module.concat
        t when is_atom(t) ->
          [ Maru.ParamType, t |> Atom.to_string |> Maru.Utils.upper_camel_case |> String.to_atom
          ] |> Module.safe_concat
      end

    coercer =
      case options[:coerce_with] do
        nil -> nil
        {:__aliases__, _, [module]} -> module |> to_string |> Maru.Utils.lower_underscore |> String.to_atom
        c when is_atom(c) -> c
        {:fn, _, _}=c -> c |> Macro.escape
        {:&, _, _}=c  -> c |> Code.eval_quoted |> elem(0)
      end

    quote do
      @param_context @param_context ++ [%Param{
        attr_name: unquote(attr_name),
        default: unquote(options[:default]),
        desc: unquote(options[:desc]),
        group: @group,
        required: unquote(required),
        nested: unquote(nested),
        coerce_with: unquote(coercer),
        parser: unquote(parser),
        validators: unquote(options) |> Dict.drop([:type, :default, :desc, :coerce_with])
      }]
    end
  end


  @actions [:mutually_exclusive, :exactly_one_of, :at_least_one_of]
  Module.eval_quoted __MODULE__, (for action <- @actions do
    quote do
      @doc "Validator: #{unquote action}"
      defmacro unquote(action)(attr_names) do
        action = unquote(action)
        quote do
          @param_context @param_context ++ [
            %Validator{action: unquote(action), attr_names: unquote(attr_names), group: @group}
          ]
        end
      end
    end
  end)
end
