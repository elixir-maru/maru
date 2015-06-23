# Router

### Namespace

```elixir
namespace :statuses do
  namespace ":user_id" do
    desc "Retrieve a user's status."
    params do
      requires :status_id, type: Integer
    end
    get ":status_id" do
      params[:user_id]   |> IO.inspect
      params[:status_id] |> IO.inspect
    end
  end
end
```

Namespaces allow parameter definitions and apply to every method within the namespace.
Its method has a number of aliases, including: `group` `resource` `resources` and `segment`. Use whichever reads the best for your API.

You can conveniently define a route parameter as a namespace using `route_param`.

```elixir
namespace :statuses do
  route_param :id do
    desc "Returns all replies for a status."
    get :replies do
      params[:id] |> IO.inspect
    end

    desc "Returns a status."
    get do
      params[:id] |> IO.inspect
    end
  end
end
```

### Type

There are a number of build-in Types, including: `String`, `Integer`, `Float`, `Boolean`, `CharList`, `Atom` and `File`.
You can also use them as `:string`, `:integer`, `:float`, `:boolean`, `:char_list`, `:atom` and `:file`.
An `Maru.Exceptions.InvalidFormatter[reason: :illegal]` exception will be raised on type change error.

`String.to_existing_atom` is used to parse `Atom` type, so a values-validator is recommanded.

### Nested Parameters
In general, Nested Parameters can be used in the same way as [grape](https://github.com/intridea/grape#validation-of-nested-parameters) except that we should use `List` and `Map` in Elixir instead of `Array` and `Hash` in Ruby.

```elixir
params do
  optional :preferences, type: List do
    requires :key
    requires :value
  end

  requires :name, type: Map do
    requires :first_name
    requires :last_name
  end
end
```

`mutually_exclusive`, `exactly_one_of` and `at_least_one_of` can also be used in the same way as [grape](https://github.com/intridea/grape#nested-mutually_exclusive-exactly_one_of-at_least_one_of) except that we should use an *explicit* List.

```elixir
params do
  requires :food do
    optional :meat
    optional :fish
    optional :rice
    at_least_one_of [:meat, :fish, :rice]
  end
  group :drink do
    optional :beer
    optional :wine
    optional :juice
    exactly_one_of [:beer, :wine, :juice]
  end
  optional :dessert do
    optional :cake
    optional :icecream
    mutually_exclusive [:cake, :icecream]
  end
end
```

### Reusable Params

You can define reusable `params` using helpers.

```elixir
defmodule API do
  helpers :name do
    optional :first_name
    optional :last_name
  end

  params do
    use :name
  end
  get do
    ...
  end
end
```

You can also define reusable `params` using shared helpers.

```elixir
defmodule SharedParams do
  use Maru.Helper

  params :period do
    optional :start_date
    optional :end_date
  end

  params :pagination do
    optional :page, type: Integer
    optional :per_page, type: Integer
  end
end

defmodule API do
  helpers SharedParams

  params do
    use [:period, :pagination]
  end
  get do
    ...
  end
end
```

### Validators

There're three build-in validators: `regexp` `values` and `allow_blank`, you can use them like this:

```elixir
params do
  requires :id,  type: :integer, regexp: ~r/^[0-9]+$/
  requires :sex, type: :atom, values: [:female, :male], default: :female
  optional :age, type: :integer, values: 18..65
end
```

An `Maru.Exceptions.UndefinedValidator` exception will be raised if validator not defined.
An `Maru.Exception.Validation` exception will be raised on validators check error.

### Custom validators

```elixir
defmodule Maru.Validations.Length do
  def validate_param!(attr_name, value, option) do
    byte(value) in option ||
      Maru.Exceptions.Validation |> raise [param: attr_name, validator: :length, value: value, option: option]
  end
end
```

```elixir
params do
  requires :text, length: 2..6
end
```


### Versioning

There are three strategies in which clients can reach your API's endpoints: `:path`, `:accept_version_header` and `:param`. The default strategy is `:path`.

#### Path
```elixir
version 'v1', using: :path
```

Using this versioning strategy, clients should pass the desired version in the URL.

```bash
curl -H http://localhost:9292/v1/statuses/public_timeline
```

#### Accept-Version Header
```elixir
version 'v1', using: :accept_version_header
```

Using this versioning strategy, clients should pass the desired version in the HTTP Accept-Version header.

```bash
curl -H "Accept-Version:v1" http://localhost:9292/statuses/public_timeline
```

#### Param
```elixir
version 'v1', using: :param
```

Using this versioning strategy, clients should pass the desired version as a request parameter, either in the URL query string or in the request body.

```bash
curl -H http://localhost:9292/statuses/public_timeline?apiver=v1
```

The default name for the query parameter is `apiver` but can be specified using the :parameter option.

```elixir
version 'v1', using: :param, parameter: "v"
```

```bash
curl -H http://localhost:9292/statuses/public_timeline?v=v1
```

### Middleware

`middleware` is a plug.
There's no `before` or `after` callback within `middleware`, `middleware` is just a plug with `response` helper of `maru`.

```elixir
defmodule Before do
  use Maru.Middleware

  def call(conn, _opts) do
    IO.puts "before request"
    conn
  end
end

defmodule API do
  use Maru.Router

  plug Before
  mount Router
end
```

### Response

`Maru.Response` protocol is defined to process response with two function: `content_type` and `resp_body`.

By default, `Map` and `List` struct will be processed by `Poison.encode!` with `application/json`, `String` will be return directly with `text/plain`, and any other struct will be processed by `to_string` with `text/plain`.

You can use a custom `struct` like this:

```elixir
defmodule User do
  defstruct name: nil, age: nil, password: nil
end

defimpl Maru.Response, for: User do
  def content_type(_) do
    "application/json"
  end

  def resp_body(user) do
    %{name: user.name, age: user.age} |> Poison.encode!
  end
end

defmodule API do
  use Maru.Router

  get do
    %User{name: "falood", age: "25", password: "123456"}
  end
end
```
