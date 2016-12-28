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

  ## Extended functions or macros

  Defined helper like this:

    defmodule Authorization do
      use Maru.Helper

      defmacro current_user do
        quote do
          var!(conn).assigns[:current_user]
        end
      end

      defmacro current_user! do
        quote do
          current_user || raise Unauthorized
        end
      end
    end

  And use it within Maru.Router like this:

      defmodule API do
        helpers Authorization

        get do
          current_user!
          ...
        end
      end
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Maru.Builder.DSLs, only: [params: 2]
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :shared_params, accumulate: true
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{module: module}) do
    shared_params = for {name, params} <- Module.get_attribute(module, :shared_params) do
      {name, params |> Macro.escape}
    end
    quote do
      def __shared_params__ do
        unquote(shared_params)
      end
    end
  end

end
