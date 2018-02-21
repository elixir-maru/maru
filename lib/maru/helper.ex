defmodule Maru.Helper do
  @moduledoc """
  Define helper for maru router.

  ## Shared Params

  Defined shared params with Maru.Helper like this:

      defmodule SharedParams do
        use Maru.Helper

        params :period do
          optional :start_date
          optional :end_date
        end

        params :pagination do
          optional :page, type: Integer
          optional :per_page, type: Integer
        end
      end

  And use shared params within Maru.Router like this:

      defmodule API do
        helpers SharedParams

        params do
          use [:period, :pagination]
        end
        get do
          ...
        end
      end
  """

  @doc false
  defmacro __using__(opts) do
    [
      quote do
        @before_compile unquote(__MODULE__)
      end,
      Maru.Builder.Parameter.using_helper(opts)
    ]
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{} = env) do
    Maru.Builder.Parameter.before_compile_helper(env)
  end
end

defmodule Maru.Helper.DSLs do
  defmacro helpers({_, _, _} = module) do
    quote do
      Maru.Builder.Parameter.after_helper(unquote(module), __ENV__)
    end
  end
end
