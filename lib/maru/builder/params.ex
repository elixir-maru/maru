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
    quote do
      @param_context @param_context ++ [
        parse_options |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: true,
          children: [],
        })
      ]
    end
  end

  defmacro requires(attr_name, options, [do: block]) do
    options = Dict.merge([type: :list], options) |> escape_options
    quote do
      param_context = @param_context
      @param_context []
      unquote(block)
      @param_context param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: true,
          children: @param_context,
        })
      ]
    end
  end

  defmacro requires(attr_name, [do: block]) do
    options = [type: :list]
    quote do
      param_context = @param_context
      @param_context []
      unquote(block)
      @param_context param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: true,
          children: @param_context,
        })
      ]
    end
  end

  defmacro requires(attr_name, options) do
    options = options |> escape_options
    quote do
      @param_context @param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: true,
          children: [],
        })
      ]
    end
  end


  @doc """
  Define a params group.
  """
  defmacro group(group_name, options \\ [], [do: block]) do
    options = Dict.merge([type: :list], options) |> escape_options
    quote do
      param_context = @param_context
      @param_context []
      unquote(block)
      @param_context param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(group_name),
          required: true,
          children: @param_context,
        })
      ]
    end
  end


  @doc """
  Define a param should be present or not.
  """
  defmacro optional(attr_name) do
    quote do
      @param_context @param_context ++ [
        parse_options |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: false,
          children: [],
        })
      ]
    end
  end

  defmacro optional(attr_name, options, [do: block]) do
    options = Dict.merge([type: :list], options) |> escape_options
    quote do
      param_context = @param_context
      @param_context []
      unquote(block)
      @param_context param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: false,
          children: @param_context,
        })
      ]
    end
  end

  defmacro optional(attr_name, [do: block]) do
    options = [type: :list]
    quote do
      param_context = @param_context
      @param_context []
      unquote(block)
      @param_context param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: false,
          children: @param_context,
        })
      ]
    end
  end

  defmacro optional(attr_name, options) do
    options = options |> escape_options
    quote do
      @param_context @param_context ++ [
        parse_options(unquote options) |> Map.merge(%{
          attr_name: unquote(attr_name),
          required: false,
          children: [],
        })
      ]
    end
  end


  def parse_options, do: %Param{}
  def parse_options(options), do: parse_options(options, %Param{})
  def parse_options([], result), do: result

  def parse_options([{:type, v} | t], result) do
    value =
      case v do
        {:__aliases__, _, [t]} -> t |> to_string |> Maru.Utils.lower_underscore |> String.to_atom
        t when is_atom(t) -> t
      end
    parse_options(t, %{result | parser: value})
  end

  def parse_options([{:coerce_with, v} | t], result) do
    value =
      case v do
        nil -> nil
        {:__aliases__, _, [module]} -> module |> to_string |> Maru.Utils.lower_underscore |> String.to_atom
        c when is_atom(c) -> c
        {:fn, _, _}=c -> c
        {:&, _, _}=c  -> c |> Code.eval_quoted |> elem(0)
      end
    parse_options(t, %{result | coerce_with: value})
  end

  def parse_options([{k, _}=h | t], result) when k in [:default, :desc, :source] do
    m = [h] |> Enum.into(%{})
    result = result |> Map.merge(m)
    parse_options(t, result)
  end

  def parse_options([h | t], %Param{validators: validators}=result) do
    parse_options(t, %{result | validators: validators ++ [h]})
  end


  defp escape_options(options) do
    options |> Enum.map(fn
      {key, value} when key in [:coerce_with, :type] -> {key, value |> Macro.escape}
      kv -> kv
    end)
  end


  @actions [:mutually_exclusive, :exactly_one_of, :at_least_one_of]
  Module.eval_quoted __MODULE__, (for action <- @actions do
    quote do
      @doc "Validator: #{unquote action}"
      defmacro unquote(action)(attr_names) do
        action = unquote(action)
        quote do
          @param_context @param_context ++ [
            %Validator{action: unquote(action), attr_names: unquote(attr_names)}
          ]
        end
      end
    end
  end)
end
