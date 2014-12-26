# Getting Started

### Install Lazymaru

1. Create a new application

        mix new my_app

2. Add lazymaru to your `mix.exs` dependencies:

        def deps do
          [ {:lazymaru, "~> 0.2.4"} ]
        end

3. List `:lazymaru` as your application dependencies:

        def application do
          [ applications: [:lazymaru] ]
        end

### Router example

```elixir
defmodule MyAPP.Router.Homepage do
  use Lazymaru.Router

  get do
    %{ hello: :world } |> json
  end
end

defmodule MyAPP.API do
  use Lazymaru.Router

  mount MyAPP.Router.Homepage

  def error(conn, e) do
    "Server Error" |> text(500)
  end
end
```

### Config example

```elixir
config :lazymaru, MyAPP.API
  port: 8880
```

### Run Server

```shell
> mix deps.get

> iex -S mix
Erlang/OTP 17 [erts-6.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]
Interactive Elixir (0.14.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Application.start :lazymaru
:ok

> curl 127.0.0.1:8880
{"hello":"world"}
```

### Generate Router Docs

`MIX_ENV=dev` is required for generating docs.

```shell
> MIX_ENV=dev mix lazymaru.routers
```
