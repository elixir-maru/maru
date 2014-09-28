defmodule Lazymaru.Exceptions do
  defmodule InvalidFormatter do
    defexception [:reason, :param, :value, :option]
    def message(e) do
      "Parsing Param Error: #{e.param}"
    end
  end

  defmodule Validation do
    defexception [:param, :validator, :value, :option]
    def message(e) do
      "Validate Param Error: #{e.param}"
    end
  end

  defmodule UndefinedValidator do
    defexception  [:param, :validator]
    def message(e) do
      "Undefined Validator: #{e.validator}"
    end
  end


  defmodule NotFound do
    defexception [:method, :path_info]
    def message(_e) do
      "NotFound"
    end
  end
end
