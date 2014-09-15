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
An `LazyException.InvalidFormatter[reason: :illegal]` exception will be raised on type change error.

`String.to_existing_atom` is used to parse `Atom` type, so a range-validator is recommanded.

### Validators

There're two build-in validators: `regexp` and `range`, you can use them like this:

```elixir
params do
  requires :id,  type: :integer, regexp: ~r/^[0-9]+$/
  requires :sex, type: :atom, range: [:female, :male], default: :female
  optional :age, type: :integer, range: 18..65
end
```

An `LazyException.InvalidFormatter[reason: :unformatted]` exception will be raised on validators check error.
Custom validators are not supported yet.
