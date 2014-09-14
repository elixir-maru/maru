defmodule LazyException do
  defmodule InvalidFormatter do
    defexception [reason: nil, param: nil, value: nil, option: nil]
    def message(exception) do
      "Parsing Param Error: #{exception.param}"
    end
  end

  defmodule NotFound do
    defexception [method: nil, path_info: nil]
    def message(_exception) do
      "NotFound"
    end
  end

end
