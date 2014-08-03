# Getting Started

### Install Lazymaru

1. Create a new application

        mix new my_app

2. Add lazymaru to your `mix.exs1` dependencies:

        def deps do
          [ {:lazymaru, github: "falood/lazymaru"} ]
        end

3. List `:lazymaru` as your application dependencies:

        def application do
          [ applications: [:lazymaru] ]
        end

### Router example

```elixir
defmodule MyAPP.Router.Homepage do
  use Lazymaru.Router, as_plug: true

  get do
    [hello: :world] |> json
  end
end
```

### Server example

```elixir
defmodule MyAPP.API do
  use Lazymaru.Server

  port 8880
  plug MyAPP.Router.Homepage
end
```

### Run Server

```shell
> mix deps.get

> iex -S mix
Erlang/OTP 17 [erts-6.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]
Interactive Elixir (0.14.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> MyAPP.API.start
{:ok, #PID<0.163.0>}

> curl 127.0.0.1:8880
{"hello":"world"}
```
