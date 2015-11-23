defmodule Maru.Builder.RoutersTest do
  use ExUnit.Case, async: true
  import Maru.Builder.Routers

  test "generate" do
    defmodule API do
      use Maru.Router
      mount Maru.Builder.RoutersTest.V1
      mount Maru.Builder.RoutersTest.V2
      mount Maru.Builder.RoutersTest.V3
      mount Maru.Builder.RoutersTest.V4
      mount Maru.Builder.RoutersTest.V5

      get do
        text conn, "get without version"
      end

      match do
        text conn, "hehe"
      end
    end

    defmodule V1 do
      use Maru.Router
      version "v1"

      desc "1.0"
      get do
        text conn, "get v1"
      end

      desc "1.1"
      post do
        text conn, "post v1"
      end
    end

    defmodule V2 do
      use Maru.Router
      version "v2", extend: "v1", at: V1

      desc "2.0"
      get do
        text conn, "get v2"
      end
    end

    defmodule V3 do
      use Maru.Router
      version "v3", extend: "v1", at: V1, only: [
        get: "/"
      ]

      desc "3.0"
      get :foo do
        text conn, "get foo v3"
      end
    end

    defmodule V4 do
      use Maru.Router
      version "v4", extend: "v3", at: V3, except: [
        get: "/"
      ]

      desc "4.0"
      get :foo do
        text conn, "get foo v4"
      end
    end

    defmodule V5 do
      use Maru.Router
      version "v5", extend: "v2", at: V2
    end

    assert %{
      nil => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "hehe"]}, desc: nil, helpers: [],
          method: {:_, [], nil}, param_context: [], path: [], version: nil
        },
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get without version"]}, desc: nil, helpers: [],
          method: "GET", param_context: [], path: [], version: nil
        }
      ],
      "v1" => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "post v1"]}, desc: "1.1", helpers: [],
          method: "POST", param_context: [], path: [], version: "v1"
        },
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get v1"]}, desc: "1.0", helpers: [],
          method: "GET", param_context: [], path: [], version: "v1"
        }
      ],
      "v2" => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get v2"]}, desc: "2.0", helpers: [],
          method: "GET", param_context: [], path: [], version: "v2"
        },
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "post v1"]}, desc: "1.1", helpers: [],
          method: "POST", param_context: [], path: [], version: "v2"
        }
      ],
      "v3" => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get foo v3"]}, desc: "3.0", helpers: [],
          method: "GET", param_context: [], path: ["foo"], version: "v3"
        },
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "post v1"]}, desc: "1.1", helpers: [],
          method: "POST", param_context: [], path: [], version: "v3"
        }
      ],
      "v4" => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get foo v4"]}, desc: "4.0", helpers: [],
          method: "GET", param_context: [], path: ["foo"], version: "v4"
        }
      ],
      "v5" => [
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "get v2"]}, desc: "2.0", helpers: [],
          method: "GET", param_context: [], path: [], version: "v5"
        },
        %Maru.Router.Endpoint{
          block: {:text, _, [_, "post v1"]}, desc: "1.1", helpers: [],
          method: "POST", param_context: [], path: [], version: "v5"
        }
      ]
    } = generate(API)
  end
end
