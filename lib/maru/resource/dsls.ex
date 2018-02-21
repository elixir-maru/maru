alias Maru.Resource

defmodule Resource.DSLs do
  alias Resource.{Helper, MaruPlug}
  alias Maru.Utils

  @doc """
  Define path prefix of current router.
  """
  defmacro prefix(path) do
    quote do
      unquote(path) |> Utils.split_path() |> Helper.push_path(__ENV__)
    end
  end

  @doc """
  Define version of current router.
  """
  defmacro version(v) do
    quote do
      Helper.set_version(unquote(v), __ENV__)
    end
  end

  @doc """
  version: "v1", do ... end:
    Version of routes within block.

  version: "v2", extend: "v1", at: V1
    Define version and extended router of current router.
  """
  defmacro version(v, do: block) do
    quote do
      r = @resource
      Helper.set_version(unquote(v), __ENV__)
      unquote(block)
      @resource r
    end
  end

  defmacro version(v, opts) do
    quote do
      Helper.set_version(unquote(v), __ENV__)
      @extend {unquote(v), unquote(opts)}
    end
  end

  @doc """
  Push a `Plug` struct to current scope.
  """
  defmacro plug(plug)

  defmacro plug({:when, _, [plug, guards]}) do
    do_plug(nil, plug, [], guards)
  end

  defmacro plug(plug) do
    do_plug(nil, plug, [], true)
  end

  @doc """
  Push a `Plug` struct with options and guards to current scope.
  """
  defmacro plug(plug, opts)

  defmacro plug(plug, {:when, _, [opts, guards]}) do
    do_plug(nil, plug, opts, guards)
  end

  defmacro plug(plug, opts) do
    do_plug(nil, plug, opts, true)
  end

  @doc """
  Push a overridable `Plug` struct to current scope.
  """
  defmacro plug_overridable(name, plug)

  defmacro plug_overridable(name, {:when, _, [plug, guards]}) do
    do_plug(name, plug, [], guards)
  end

  defmacro plug_overridable(name, plug) do
    do_plug(name, plug, [], true)
  end

  @doc """
  Push a overridable `Plug` struct with options and guards to current scope.
  """
  defmacro plug_overridable(name, plug, opts)

  defmacro plug_overridable(name, plug, {:when, _, [opts, guards]}) do
    do_plug(name, plug, opts, guards)
  end

  defmacro plug_overridable(name, plug, opts) do
    do_plug(name, plug, opts, true)
  end

  defp do_plug(name, plug, opts, guards) do
    quote do
      Helper.push_plug(
        %MaruPlug{
          name: unquote(name),
          plug: unquote(plug),
          options: unquote(opts),
          guards: unquote(Macro.escape(guards))
        },
        __ENV__
      )
    end
  end

  @namespaces [:namespace, :group, :resource, :resources, :segment]

  for namespace <- @namespaces do
    @doc "Namespace alias #{namespace}."
    defmacro unquote(namespace)(do: block), do: block

    defmacro unquote(namespace)(path, do: block) do
      namespace = unquote(namespace)

      quote do
        @namespace_context %{
          namespace: unquote(namespace)
        }
        r = @resource
        unquote(path) |> Utils.split_path() |> Helper.push_path(__ENV__)
        Maru.Builder.Pipeline.before_parse_namespace(__ENV__)
        Maru.Builder.Parameter.before_parse_namespace(__ENV__)
        unquote(block)
        @resource r
      end
    end
  end

  @doc "Special namespace which save path to param list."
  defmacro route_param(param, do: block) when is_atom(param) do
    quote do
      @namespace_context %{
        namespace: :route_param,
        parameter: unquote(param),
        options: []
      }
      r = @resource
      Helper.push_path([unquote(param)], __ENV__)
      Maru.Builder.Pipeline.before_parse_namespace(__ENV__)
      Maru.Builder.Parameter.before_parse_namespace(__ENV__)
      unquote(block)
      @resource r
    end
  end

  @doc "Special namespace which save path to param list with options."
  defmacro route_param(param, options, do: block) when is_atom(param) do
    options = options |> Maru.Utils.expand_alias(__CALLER__) |> Macro.escape()

    quote do
      @namespace_context %{
        namespace: :route_param,
        parameter: unquote(param),
        options: unquote(options)
      }
      r = @resource
      Helper.push_path([unquote(param)], __ENV__)
      Maru.Builder.Pipeline.before_parse_namespace(__ENV__)
      Maru.Builder.Parameter.before_parse_namespace(__ENV__)
      unquote(block)
      @resource r
    end
  end

  @methods [:get, :post, :put, :patch, :delete, :head, :options]

  for method <- @methods do
    @doc "Handle #{method} method."
    defmacro unquote(method)(path \\ "", do: block) do
      method = unquote(method)

      quote do
        %{
          method: unquote(method),
          path: Utils.split_path(unquote(path)),
          block: unquote(Macro.escape(block))
        }
        |> Helper.endpoint(__ENV__)
      end
    end
  end

  @doc "Handle all method."
  defmacro match(path \\ "", do: block) do
    quote do
      %{
        method: :match,
        path: Utils.split_path(unquote(path)),
        block: unquote(Macro.escape(block))
      }
      |> Helper.endpoint(__ENV__)
    end
  end

  @doc """
  Mount another router to current router.
  """
  defmacro mount({_, _, [h | t]} = mod) do
    h = Module.concat([h])

    module =
      __CALLER__.aliases
      |> Keyword.get(h, h)
      |> Module.split()
      |> Enum.concat(t)
      |> Module.concat()

    try do
      true = {:__routes__, 0} in module.__info__(:functions)
    rescue
      [UndefinedFunctionError, MatchError] ->
        raise """
          #{inspect(module)} is not an available Maru.Router.
          If you mount it to another module written at the same file,
          make sure this module at the front of the file.
        """
    end

    quote do
      Helper.mount(unquote(mod), __ENV__)
    end
  end
end
