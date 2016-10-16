defmodule Maru.Struct.Dependent do
  @module false

  defstruct information: nil,
            runtime: nil
end

defmodule Maru.Struct.Dependent.Information do
  @module false

  defstruct depends:  [],
            children: []
end

defmodule Maru.Struct.Dependent.Runtime do
  @module false

  defstruct validators: [],
            children:   []
end
