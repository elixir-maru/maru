defmodule Maru.Router do
  defmacro __using__(_) do
    quote do
      use Maru.Builder
    end
  end

  defmodule Param do
    @moduledoc false

    defstruct attr_name: nil, default: nil, desc: nil, group: [], required: true, nested: false, parser: nil, validators: []
  end

  defmodule Validator do
    @moduledoc false

    defstruct action: nil, attr_names: [], group: []
  end

  defmodule Resource do
    @moduledoc false

    defstruct path: [], param_context: []
  end
end
