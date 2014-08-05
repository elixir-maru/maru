# Lazymaru

> Elixir copy of [grape](http://intridea.github.io/grape/) for creating REST-like APIs.

[![Build Status](https://api.travis-ci.org/falood/lazymaru.svg)](https://travis-ci.org/falood/lazymaru/)

## Usage

```elixir
defmodule Router.User do
  use Lazymaru.Router

  namespace :user do
    route_param :id do
      get do
        [ user: params[:id] ] |> json
      end

      desc "description"
      params do
        requires :age,    type: Integer, range: 18..65
        requires :sex,    type: Atom, range: [:male, :female], default: :female
        optional :intro,  type: String, regexp: ~r/^[a-z]+$/
        optional :avatar, type: File
      end
      post do
        ...
      end
    end
  end
end

defmodule Router.Homepage do
  use Lazymaru.Router, as_plug: true

  resources do
    get do
      [ hello: :world ] |> json
    end

    mount Router.User
  end
end

defmodule Wrapper do
  use Lazymaru.Wrapper

  def wrap(conn, _opts, func) do
    try do
      func.(conn)
    rescue
      _ ->
        "Not Found" |> text(404)
    end
  end
end

defmodule MyAPP.API do
  use Lazymaru.Server

  port 8880
  plug Wrapper
  plug Plug.Static "/static", "/my/static/path/"
  plug Router.Homepage
end

MyAPP.API.start
```

For more info, you can move to [Getting Started Guide](https://github.com/falood/lazymaru/blob/master/guide/getting_started.md), [Router Guide](https://github.com/falood/lazymaru/blob/master/guide/router.md) and [Wrapper Guide](https://github.com/falood/lazymaru/blob/master/guide/wrapper.md).

## TODO

- [ ] realtime connection
- [X] params DSL
- [X] header DSL
- [X] assign DSL
- [X] helper DSL
- [ ] generate docs by desc DSL
- [ ] custom params validators
- [ ] https support
