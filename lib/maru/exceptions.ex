defmodule Maru.Exceptions do
  defmodule InvalidFormat do
    @moduledoc """
    Raised when get param from request.

    options of reason:

        * `:required` raised when a required param not given
        * `:illegal` raised when parse param error
    """

    defexception [:reason, :param, :value, plug_status: 400]

    def message(e) do
      "Parsing Param Error: #{e.param}"
    end
  end

  defmodule Validation do
    @moduledoc """
    Raised when validate param failed.
    """

    defexception [:param, :validator, :value, :option, plug_status: 400]

    def message(e) do
      "Validate Param Error: #{inspect(e.param)}"
    end
  end

  defmodule UndefinedValidator do
    @moduledoc """
    Raised when validater not found.
    """

    defexception [:validator]

    def message(e) do
      "Undefined Validator: #{e.validator}"
    end
  end

  defmodule UndefinedType do
    @moduledoc """
    Raised when type not found.
    """

    defexception [:type]

    def message(e) do
      "Undefined Type: #{e.type}"
    end
  end

  defmodule NotFound do
    @moduledoc """
    Raised when request path don't match any router.
    Catch this exception and return 404 like this:

        rescue_from Maru.Exceptions.NotFound do
          conn
          |> put_status(404)
          |> text("Not Found")
        end
    """

    defexception [:method, :path_info, plug_status: 404]

    def message(_e) do
      "NotFound"
    end
  end

  defmodule MethodNotAllowed do
    @moduledoc """
    Raised when request path matched but method not matched.
    Catch this exception and return 405 like this:

        rescue_from Maru.Exceptions.MethodNotAllowed do
          conn
          |> put_status(405)
          |> text("Method Not Allowed")
        end
    """

    defexception [:method, :request_path, plug_status: 405]

    def message(_e) do
      "MethodNotAllowed"
    end
  end
end
