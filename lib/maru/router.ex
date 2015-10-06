defmodule Maru.Router do
  defmacro __using__(_) do
    quote do
      use Maru.Builder
    end
  end

  defmodule Param do
    @moduledoc false

    [ attr_name: nil,
      default: nil,
      desc: nil,
      required: true,
      children: [],
      coerce_with: nil,
      parser: nil,
      validators: []
    ] |> defstruct
  end

  defmodule Validator do
    @moduledoc false

    defstruct action: nil, attr_names: []
  end

  defmodule Resource do
    @moduledoc false

    defstruct path: [], param_context: []
  end
end
