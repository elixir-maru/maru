defmodule Maru.Exceptions do
  defmodule InvalidFormatter do
    @moduledoc """
    Raised when get param from request.

    options of reason:

        * `:required` raised when a required param not given
        * `:illegal` raised when parse ram crashed by &parser.from/1
    """

    defexception [:reason, :param, :value, :option]
    def message(e) do
      "Parsing Param Error: #{e.param}"
    end
  end

  defmodule Validation do
    @moduledoc """
    Raised when validate param failed.
    """

    defexception [:param, :validator, :value, :option]
    def message(e) do
      "Validate Param Error: #{e.param}"
    end
  end

  defmodule UndefinedValidator do
    @moduledoc """
    Raised when validater not found.
    """

    defexception  [:param, :validator]
    def message(e) do
      "Undefined Validator: #{e.validator}"
    end
  end

  defmodule NotFound do
    @moduledoc """
    Raised when request path don't match any router.
    Catch this exception and return 404 like this:

        rescue_from Maru.Exceptions.NotFound do
          status 404
          "Not Found"
        end
    """

    defexception [:path_info]
    def message(_e) do
      "NotFound"
    end
  end

  defmodule MethodNotAllow do
    @moduledoc """
    Raised when request path matched but method not matched.
    Catch this exception and return 405 like this:

        rescue_from Maru.Exceptions.MethodNotAllow do
          status 405
          "Method Not Allow"
        end
    """

    defexception [:method, :request_path]
    def message(_e) do
      "MethodNotAllow"
    end
  end
end
