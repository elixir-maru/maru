defmodule LazyException do
  defexception InvalidFormatter, [reason: nil, param: nil, option: nil] do
    def message(exception) do
      "Parsing Param Error: #{exception.param}"
    end
  end
end
