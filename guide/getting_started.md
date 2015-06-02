# Getting Started

### Install Maru

1. Create a new application

        mix new my_app

2. Add maru to your `mix.exs` dependencies:

        def deps do
          [ {:maru, "~> 0.3.0"} ]
        end

3. List `:maru` as your application dependencies:

        def application do
          [ applications: [:maru] ]
        end

### Router example

```elixir
defmodule MyAPP.Router.Homepage do
  use Maru.Router

  get do
    %{ hello: :world } |> json
  end
end

defmodule MyAPP.API do
  use Maru.Router

  mount MyAPP.Router.Homepage

  def error(conn, e) do
    "Server Error" |> text(500)
  end
end
```

### Config example

```elixir
config :maru, MyAPP.API,
  http: [port: 8880]
```

### Run Server

```shell
> mix deps.get

> iex -S mix
Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]
Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Application.start :maru
:ok

> curl 127.0.0.1:8880
{"hello":"world"}
```

### Generate Router Docs

`MIX_ENV=dev` is required for generating docs.

```shell
> MIX_ENV=dev mix maru.routers
```
