alias Maru.Builder.Parameter

defmodule Parameter.Validator do
  @moduledoc false

  defstruct information: nil, runtime: nil
end

defmodule Parameter.Validator.Information do
  @moduledoc false

  defstruct action: nil
end

defmodule Parameter.Validator.Runtime do
  @moduledoc false

  defstruct validate_func: nil
end
