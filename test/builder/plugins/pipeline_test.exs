defmodule Maru.Builder.PipelineTest do
  use ExUnit.Case, async: true

  alias Maru.Resource.MaruPlug

  test "pipeline for namespaces" do
    defmodule Namespace do
      use Maru.Builder

      pipeline do
        plug A
      end
      resources :p1 do
        def resource, do: @resource
      end
    end

    assert %Maru.Resource{
      path: ["p1"],
      plugs: [%MaruPlug{guards: true, name: nil, options: [], plug: A}],
    } = Namespace.resource
  end

  test "pipeline for method" do
    defmodule Method do
      use Maru.Builder

      pipeline do
        plug A
      end
      get do
        text(conn, "ok")
      end
    end

    assert %Maru.Router{
      method: :get,
      module: Maru.Builder.PipelineTest.Method,
      path: [],
      plugs: [%MaruPlug{guards: true, name: nil, options: [], plug: A}],
    } = Method.__routes__ |> List.first
  end
end
