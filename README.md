# Maru

> Elixir copy of [grape](http://intridea.github.io/grape/) for creating REST-like APIs.

[![Build Status](https://img.shields.io/travis/falood/maru.svg?style=flat-square)](https://travis-ci.org/falood/maru)
[![Hex.pm Version](https://img.shields.io/hexpm/v/maru.svg?style=flat-square)](https://hex.pm/packages/maru)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/maru.svg?style=flat-square)](https://hex.pm/packages/maru)

## Usage

```elixir
defmodule Router.User do
  use Maru.Router

  namespace :user do
    route_param :id do
      get do
        %{ user: params[:id] }
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
      %{ hello: :world }
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

    status 401
    "Unauthorized"
  end

  rescue_from :all do
    status 500
    "Server Error"
  end
end
```

then add the `maru` to your `config/config.exs`
```elixir
config :maru, MyAPP.API,
  port: 8880
```

For more information, check out  [Guides](https://maru.readme.io) and [Examples](https://github.com/falood/maru_examples)

## TODO

- [ ] rails like url params parser [plug#111](https://github.com/elixir-lang/plug/issues/111)
- [ ] jsonp support
- [ ] validation, before, before\_validation, after, after\_validation
