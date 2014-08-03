# Wrapper

### Use Wrapper
A `Lazymaru.Router` is a `Plug` and a `Lazymar.Wrapper` is a `Plug.Wrapper` with Lazymaru's `Response DSL`. So you can use them as the same way as plug.

```elixir
defmodule PrepareWrapper do
  use Lazymaru.Wrapper

  def init(opts), do: opts

  def wrap(conn, \_opts, func) do
     user = BAISIC\_AUTH(conn) || nil
     assign :current_user, user
     func.(conn)
  end
end

defmodule ExceptionWrapper do
  use Lazymaru.Wrapper

  def call(conn, _opts, func) do
    try do
      func.(conn)
    rescue
      e in [LazyException.InvalidFormatter] ->
        e.message |> text(500)
      FunctionClauseError ->
        "Not Found" |> text(404)
    end
  end
end

defmodule MyAPP.API do
  use Lazymaru.Server

  port 8880
  plug PrepareWrapper
  plug ExceptionWrapper
  plug MyRouter
end
```
