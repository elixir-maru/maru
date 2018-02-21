alias Maru.Builder.Parameter

defmodule Parameter.DSLs do
  @doc """
  Define params block of current endpoint.
  """

  alias Parameter.Helper
  alias Parameter
  alias Parameter.{Information, Dependent, Validator}
  alias Maru.Utils

  defmacro params(name, do: block) do
    quote do
      @shared_params unquote({name, block |> Macro.escape()})
    end
  end

  defmacro params(do: block) do
    quote do
      import Maru.Resource.DSLs, only: []
      import Kernel, except: [use: 1]
      import Parameter.DSLs
      import Parameter.DSLs, except: [params: 1]
      @group []
      unquote(block)
      import Parameter.DSLs, only: [params: 1]
      import Kernel
      import Maru.Resource.DSLs
    end
  end

  @doc false
  defmacro use(param) when is_atom(param) do
    quote do
      params = @shared_params[unquote(param)]
      Module.eval_quoted(__MODULE__, params, [], __ENV__)
    end
  end

  defmacro use(params) do
    quote do
      for i <- unquote(params) do
        params = @shared_params[i]
        Module.eval_quoted(__MODULE__, params, [], __ENV__)
      end
    end
  end

  @doc """
  Define a param should be present.
  """
  defmacro requires(attr_name) do
    quote do
      [attr_name: unquote(attr_name), required: true] |> Helper.parse() |> Helper.push(__ENV__)
    end
  end

  defmacro requires(attr_name, options, do: block) do
    options =
      [type: :list]
      |> Keyword.merge(options)
      |> Utils.expand_alias(__CALLER__)
      |> Macro.escape()

    quote do
      s = Helper.pop(__ENV__)
      unquote(block)
      children = Helper.pop(__ENV__)
      Helper.push(s, __ENV__)

      [attr_name: unquote(attr_name), required: true, children: children]
      |> Enum.concat(unquote(options))
      |> Helper.parse()
      |> Helper.push(__ENV__)
    end
  end

  defmacro requires(attr_name, [do: _] = block) do
    quote do
      requires(unquote(attr_name), [type: :list], unquote(block))
    end
  end

  defmacro requires(attr_name, options) do
    options = options |> Utils.expand_alias(__CALLER__) |> Macro.escape()

    quote do
      [attr_name: unquote(attr_name), required: true]
      |> Enum.concat(unquote(options))
      |> Helper.parse()
      |> Helper.push(__ENV__)
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
      [attr_name: unquote(attr_name), required: false] |> Helper.parse() |> Helper.push(__ENV__)
    end
  end

  defmacro optional(attr_name, options, do: block) do
    options =
      [type: :list]
      |> Keyword.merge(options)
      |> Utils.expand_alias(__CALLER__)
      |> Macro.escape()

    quote do
      s = Helper.pop(__ENV__)
      unquote(block)
      children = Helper.pop(__ENV__)
      Helper.push(s, __ENV__)

      [attr_name: unquote(attr_name), required: false, children: children]
      |> Enum.concat(unquote(options))
      |> Helper.parse()
      |> Helper.push(__ENV__)
    end
  end

  defmacro optional(attr_name, [do: _] = block) do
    quote do
      optional(unquote(attr_name), [type: :list], unquote(block))
    end
  end

  defmacro optional(attr_name, options) do
    options = options |> Utils.expand_alias(__CALLER__) |> Macro.escape()

    quote do
      [attr_name: unquote(attr_name), required: false]
      |> Enum.concat(unquote(options))
      |> Helper.parse()
      |> Helper.push(__ENV__)
    end
  end

  defmacro given(attr, do_block) when is_atom(attr) do
    quote do
      given([unquote(attr)], unquote(do_block))
    end
  end

  defmacro given(attrs, do: block) do
    Enum.all?(attrs, fn
      attr when is_atom(attr) ->
        true

      {_, {:&, _, _}} ->
        true

      # fun/1
      {_, {:fn, _, [{:->, _, [[_] | _]}]}} ->
        true

      _ ->
        false
    end) || raise "error dependent format"

    depends =
      Enum.map(attrs, fn
        {param, _} -> param
        param -> param
      end)

    validators =
      Enum.map(attrs, fn
        {param, func} ->
          func = Utils.expand_alias(func, __CALLER__)

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
      end)
      |> Macro.escape()

    quote do
      s = Helper.pop(__ENV__)
      unquote(block)
      children = Helper.pop(__ENV__)
      Helper.push(s, __ENV__)

      children_information = Maru.Utils.get_nested(children, :information)
      children_runtime = Maru.Utils.get_nested(children, :runtime)
      validators = unquote(validators)

      %Dependent{
        information: %Dependent.Information{
          depends: unquote(depends),
          children: children_information
        },
        runtime:
          quote do
            %Dependent.Runtime{
              validators: unquote(validators),
              children: unquote(children_runtime)
            }
          end
      }
      |> Helper.push(__ENV__)
    end
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
          @parameters
          |> Enum.filter(fn
            %Parameter{} -> true
            _ -> false
          end)
          |> Enum.map(fn %Parameter{information: %Information{attr_name: attr_name}} ->
            attr_name
          end)

        runtime =
          quote do
            %Validator.Runtime{
              validate_func: fn result ->
                unquote(module).validate!(unquote(attr_names), result)
              end
            }
          end

        %Validator{
          information: %Validator.Information{action: unquote(action)},
          runtime: runtime
        }
        |> Helper.push(__ENV__)
      end
    end

    defmacro unquote(action)(attr_names) do
      action = unquote(action)
      module = Utils.make_validator(unquote(action))

      validator =
        %Validator{
          information: %Validator.Information{action: action},
          runtime:
            quote do
              %Validator.Runtime{
                validate_func: fn result ->
                  unquote(module).validate!(unquote(attr_names), result)
                end
              }
            end
        }
        |> Macro.escape()

      quote do
        Helper.push(unquote(validator), __ENV__)
      end
    end
  end
end
