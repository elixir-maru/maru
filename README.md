# Maru

> REST-like API micro-framework for elixir inspired by [grape](http://intridea.github.io/grape/).

[![Build Status](https://img.shields.io/travis/falood/maru.svg?style=flat-square)](https://travis-ci.org/falood/maru)
[![Hex.pm Version](https://img.shields.io/hexpm/v/maru.svg?style=flat-square)](https://hex.pm/packages/maru)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/falood/maru.svg?branch=master&style=flat-square)](https://beta.hexfaktor.org/github/falood/maru)
[![Docs](https://inch-ci.org/github/falood/maru.svg?branch=master&style=flat-square)](https://inch-ci.org/github/falood/maru)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/maru.svg?style=flat-square)](https://hex.pm/packages/maru)
## Usage

```elixir
defmodule Router.User do
  use Maru.Router

  namespace :user do
    route_param :id do
      get do
        json conn, %{ user: params[:id] }
      end

      desc "description"
      params do
        requires :age,    type: Integer, values: 18..65
        requires :sex,    type: Atom, values: [:male, :female], default: :female
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
  use Maru.Router

  resources do
    get do
      json conn, %{ hello: :world }
    end

    mount Router.User
  end
end


defmodule MyAPP.API do
  use Maru.Router

  plug Plug.Static, at: "/static", from: "/my/static/path/"
  mount Router.Homepage

  rescue_from Unauthorized, as: e do
    IO.inspect e

    conn
    |> put_status(401)
    |> text("Unauthorized")
  end

  rescue_from :all do
    conn
    |> put_status(500)
    |> text("Server Error")
  end
end
```

then add the `maru` to your `config/config.exs`
```elixir
config :maru, MyAPP.API,
  http: [port: 8880]
```

For more information, check out  [Guides](https://maru.readme.io) and [Examples](https://github.com/falood/maru_examples)
