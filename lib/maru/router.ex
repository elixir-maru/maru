defmodule Maru.Router do
  defmacro __using__(_) do
    quote do
      use Maru.Builder
    end
  end


  defmodule Validator do
    @moduledoc false

    defstruct action: nil, attr_names: []
  end


  defmodule Param do
    @moduledoc false

    defstruct attr_name:   nil,
              source:      nil,
              default:     nil,
              desc:        nil,
              required:    true,
              children:    [],
              coerce_with: nil,
              parser:      :term,
              validators:  []

    defmacro snapshot do
      quote do
        @param_context
      end
    end

    defmacro restore(value) do
      quote do
        @param_context unquote(value)
      end
    end

    defmacro push(value) when is_list(value) do
      quote do
        @param_context @param_context ++ unquote(value)
      end
    end

    defmacro push(value) do
      quote do
        @param_context @param_context ++ [unquote(value)]
      end
    end

    defmacro pop do
      quote do
        try do
          @param_context
        after
          @param_context []
        end
      end
    end
  end


  defmodule Resource do
    @moduledoc false

    defstruct path: [], param_context: []

    defmacro snapshot do
      quote do
        @resource
      end
    end

    defmacro restore(value) do
      quote do
        @resource unquote(value)
      end
    end


    defmacro push_path(value) when is_list(value) do
      quote do
        %Resource{path: path} = resource =  @resource
        @resource %{
          resource |
          path: path ++ unquote(value),
        }
      end
    end

    defmacro push_path(value) do
      quote do
        %Resource{path: path} = resource =  @resource
        @resource %{
          resource |
          path: path ++ [unquote(value)],
        }
      end
    end

    defmacro push_param(value) do
      quote do
        %Resource{param_context: param} = resource =  @resource
        param_context =
          case unquote(value) do
            v when is_list(v) -> param ++ v
            v                 -> param ++ [v]
          end
        @resource %{ resource | param_context: param_context }
      end
    end

  end

end
