defmodule Maru.Struct.Validator do
  @moduledoc false

  defstruct information: nil, runtime: nil
end

defmodule Maru.Struct.Validator.Information do
  @moduledoc false

  defstruct action: nil
end

defmodule Maru.Struct.Validator.Runtime do
  @moduledoc false

  defstruct validate_func: nil
end
