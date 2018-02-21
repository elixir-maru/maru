alias Maru.Builder.Parameter

defmodule Parameter.Dependent do
  @moduledoc false

  defstruct information: nil,
            runtime: nil
end

defmodule Parameter.Dependent.Information do
  @moduledoc false

  defstruct depends: [],
            children: []
end

defmodule Parameter.Dependent.Runtime do
  @moduledoc false

  defstruct validators: [],
            children: []
end
