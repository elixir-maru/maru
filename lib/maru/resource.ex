alias Maru.Resource

defmodule Resource do
  defstruct [
    path:       [],
    parameters: [],
    plugs:      [],
    helpers:    [],
    version:    nil,
  ]


  defmacro __using__(_) do
    quote do
      import Resource.DSLs
      @resource %Resource{}
      @extend   nil
    end
  end
end
