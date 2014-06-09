defmodule LazyException.InvalidFormatter do
  defexception [reason: nil, param: nil, option: nil]
  def message(exception) do
    "Parsing Param Error: #{exception.param}"
  end
end
