# Maru

> REST-like API micro-framework for elixir inspired by [grape](https://github.com/ruby-grape/grape).

[![Build Status](https://img.shields.io/travis/elixir-maru/maru.svg?style=flat-square)](https://travis-ci.org/elixir-maru/maru)
[![Hex.pm Version](https://img.shields.io/hexpm/v/maru.svg?style=flat-square)](https://hex.pm/packages/maru)
[![Docs](https://inch-ci.org/github/elixir-maru/maru.svg?branch=master&style=flat-square)](https://inch-ci.org/github/elixir-maru/maru)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/maru.svg?style=flat-square)](https://hex.pm/packages/maru)

## Installation

To get started with Maru, add the following to `mix.exs`:

```elixir
def deps() do
  [
    {:maru, "~> 0.13"},
    {:cowboy, "~> 2.3"},

    # Optional dependency, you can also add your own json_library dependency
    # and config with `config :maru, json_library, YOUR_JSON_LIBRARY`.
    {:jason, "~> 1.0"}
  ]
end
```

## Usage

```elixir
defmodule Router.User do
  use MyApp.Server

  namespace :user do
    route_param :id do
      get do
        json(conn, %{ user: params[:id] })
      end

      desc "description"
      params do
        requires :age,    type: Integer, values: 18..65
        requires :gender, type: Atom, values: [:male, :female], default: :female
        group    :name,   type: Map do
          requires :first_name
          requires :last_name
        end
        optional :intro,  type: String, regexp: ~r/^[a-z]+$/
        optional :avatar, type: File
        optional :avatar_url, type: String
        exactly_one_of [:avatar, :avatar_url]
      end
      post do
        ...
      end
    end
  end
end

defmodule Router.Homepage do
  use MyApp.Server

  resources do
    get do
      json(conn, %{ hello: :world })
    end

    mount Router.User
  end
end


defmodule MyAPP.API do
  use MyApp.Server

  before do
    plug Plug.Logger
    plug Plug.Static, at: "/static", from: "/my/static/path/"
  end

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Jason,
    parsers: [:urlencoded, :json, :multipart]

  mount Router.Homepage

  rescue_from Unauthorized, as: e do
    IO.inspect e

    conn
    |> put_status(401)
    |> text("Unauthorized")
  end

  rescue_from [MatchError, RuntimeError], with: :custom_error

  rescue_from :all, as: e do
    conn
    |> put_status(Plug.Exception.status(e))
    |> text("Server Error")
  end

  defp custom_error(conn, exception) do
    conn
    |> put_status(500)
    |> text(exception.message)
  end
end

defmodule MyAPP.Server do
  use Maru.Server, otp_app: :my_app
end
```

Then configure `maru`:

```elixir
# config/config.exs
config :my_app, MyAPP.Server,
  adapter: Plug.Adapters.Cowboy2,
  plug: MyAPP.API,
  scheme: :http,
  port: 8880

config :my_app,
  maru_servers: [MyApp.Server]
```

For more information, check out  [Guides](https://maru.readme.io) and [Examples](https://github.com/elixir-maru/maru_examples)
