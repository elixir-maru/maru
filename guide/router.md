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
An `Lazymaru.Exceptions.InvalidFormatter[reason: :illegal]` exception will be raised on type change error.

`String.to_existing_atom` is used to parse `Atom` type, so a values-validator is recommanded.

### Validators

There're two build-in validators: `regexp` and `values`, you can use them like this:

```elixir
params do
  requires :id,  type: :integer, regexp: ~r/^[0-9]+$/
  requires :sex, type: :atom, values: [:female, :male], default: :female
  optional :age, type: :integer, values: 18..65
end
```

An `Lazymaru.Exceptions.UndefinedValidator` exception will be raised if validator not defined.
An `Lazymaru.Exception.Validation` exception will be raised on validators check error.

### Custom validators

```elixir
defmodule Lazymaru.Validations.Length do
  def validate_param!(attr_name, value, option) do
    byte(value) in option ||
      Lazymaru.Exceptions.Validation |> raise [param: attr_name, validator: :length, value: value, option: option]
  end
end
```

```elixir
params do
  requires :text, length: 2..6
end
```
