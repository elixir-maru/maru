# Maru

> Elixir copy of [grape](http://intridea.github.io/grape/) for creating REST-like APIs.

[![Build Status](https://api.travis-ci.org/falood/maru.svg)](https://travis-ci.org/falood/maru/)
[![hex.pm Version](https://img.shields.io/hexpm/v/maru.svg)](https://hex.pm/packages/maru)

## Usage

```elixir
defmodule Router.User do
  use Maru.Router

  namespace :user do
    route_param :id do
      get do
        %{ user: params[:id] } |> json
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
      %{ hello: :world } |> json
    end

    mount Router.User
  end
end


defmodule MyAPP.API do
  use Maru.Router

  plug Plug.Static, at: "/static", from: "/my/static/path/"
  mount Router.Homepage

  def error(conn, _e) do
    "Server Error" |> text(500)
  end
end
```

then add the `maru` to your `config/config.exs`
```elixir
config :maru, MyAPP.API,
  port: 8880
```

For more info, you can move to [Getting Started Guide](https://github.com/falood/maru/blob/master/guide/getting_started.md), [Router Guide](https://github.com/falood/maru/blob/master/guide/router.md) and [Examples](https://github.com/falood/maru_examples)

## TODO

- [X] params macro
- [X] `mutually_exclusive` `exactly_one_of` `at_least_one_of` macro for params
- [X] group macro for params
- [X] header macro
- [X] assign macro
- [X] helper macro
- [X] generate docs
- [X] custom params validators
- [X] version support
- [X] https support
- [ ] <del>generate detail docs include params</del>
- [ ] swagger support [#1](https://github.com/falood/maru/issues/1)
- [ ] rails like url params parser [plug#111](https://github.com/elixir-lang/plug/issues/111)
- [ ] params unused warning
- [ ] complex path for namespaces
- [X] prefix macro
- [ ] work with phoenix guide
- [ ] HTTP Status Code
- [X] reusable params
- [ ] redirecting
- [ ] error!
- [ ] jsonp support
- [ ] validation, before, before\_validation, after, after\_validation
