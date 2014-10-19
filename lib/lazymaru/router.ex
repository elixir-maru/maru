defmodule Lazymaru.Router do
  defmacro __using__(_) do
    quote do
      use Lazymaru.Builder
    end
  end

  defmodule Param do
    defstruct attr_name: nil, default: nil, group: [], required: true, nested: false, parser: nil, validators: []
  end

  defmodule Validator do
    defstruct action: nil, attr_names: [], group: []
  end

  defmodule Resource do
    defstruct path: [], param_context: []
  end
end
