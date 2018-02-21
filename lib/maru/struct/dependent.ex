defmodule Maru.Struct.Dependent do
  @moduledoc false

  defstruct information: nil,
            runtime: nil
end

defmodule Maru.Struct.Dependent.Information do
  @moduledoc false

  defstruct depends: [],
            children: []
end

defmodule Maru.Struct.Dependent.Runtime do
  @moduledoc false

  defstruct validators: [],
            children: []
end
