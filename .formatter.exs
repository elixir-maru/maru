# Used by "mix format"
[
  inputs: [
    ".formatter.exs",
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: [
    mount: 1,
    params: :*,
    helpers: 1,
    version: 1,
    plug: :*,
    plug_overridable: :*,
    requires: :*,
    optional: :*,
    group: :*,
    given: :*,
    mutually_exclusive: 1,
    exactly_one_of: 1,
    at_least_one_of: 1,
    all_or_none_of: 1,
    prefix: :*,
    rescue_from: :*,
    desc: :*,
    detail: 1,
    status: 2
  ],
  export: [
    locals_without_parens: [
      mount: 1,
      params: :*,
      helpers: 1,
      version: 1,
      plug: :*,
      plug_overridable: :*,
      requires: :*,
      optional: :*,
      group: :*,
      given: :*,
      mutually_exclusive: 1,
      exactly_one_of: 1,
      at_least_one_of: 1,
      all_or_none_of: 1,
      prefix: :*,
      rescue_from: :*,
      desc: :*,
      detail: 1,
      status: 2
    ]
  ]
]
