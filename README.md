# Lazymaru

> Elixir copy of [grape](http://intridea.github.io/grape/) for creating REST-like APIs.

[![Build Status](https://api.travis-ci.org/falood/lazymaru.svg)](https://travis-ci.org/falood/lazymaru/)
[![hex.pm Version](https://img.shields.io/hexpm/v/lazymaru.svg)](https://hex.pm/packages/lazymaru)

## Usage

```elixir
defmodule Router.User do
  use Lazymaru.Router

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
  use Lazymaru.Router

  resources do
    get do
      %{ hello: :world } |> json
    end

    mount Router.User
  end
end


defmodule MyAPP.API do
  use Lazymaru.Router

  plug Plug.Static "/static", "/my/static/path/"
  mount Router.Homepage

  def error(conn, _e) do
    "Server Error" |> text(500)
  end
end
```

then add the `lazymaru` to your `config/config.exs`
```elixir
config :lazymaru, MyAPP.API
  port: 8880
```

For more info, you can move to [Getting Started Guide](https://github.com/falood/lazymaru/blob/master/guide/getting_started.md) and [Router Guide](https://github.com/falood/lazymaru/blob/master/guide/router.md)

## TODO

- [X] params DSL
- [X] `mutually_exclusive` `exactly_one_of` `at_least_one_of` DSL for params
- [X] group DSL for params
- [X] header DSL
- [X] assign DSL
- [X] helper DSL
- [ ] generate docs by desc DSL
- [X] custom params validators
- [ ] https support
