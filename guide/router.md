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
