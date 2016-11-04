## Changelog

[Upgrade Instructions](https://maru.readme.io/docs/upgrade-instructions-from-v09) From v0.9 to v0.10

## v0.10.6-dev

## v0.10.5 (2016-10-30)
* Enhancements
  * add `:keep_blank` option for params
  * add `:given` DSL for dependent parameters
  * make `rescue_from` works for all maru router
  * support `with` option for `rescue_from` DSL
  * bring maru's params parser to phoenix

* Bugfix
  * allow set optional params to false and blank value by default

## v0.10.4 (2016-8-19)
* Enhancements
  * support one-line nested list params
  * new DSLs for unittest

## v0.10.3 (2016-7-11)
* Enhancements
  * add detail and responses for description
  * add response helper functions `put_maru_conn/1` and `get_maru_conn/0`
  * pass modified conn to `rescue_from` block

## v0.10.2 (2016-6-28)
* Bugfix
  * fix v1.3.0 exception warning

## v0.10.1 (2016-6-14)
* Bugfix
  * jumbled routes order
  * custom type and validation error

## v0.10.0 (2016-6-11)
* Enhancements
  * totally rewrite route logic
  * totally rewrite params parsing logic and DSLs
  * add overridable plug
  * support top-level plug
  * split Route and Endpoint

* Deprecations
  * `coercion` is deprecated in favor of `type`

## v0.9.6 (2016-4-5)
* Bugfix
  * define helper functions for all environments except `:prod`

## v0.9.5 (2016-3-15)
* Enhancements
  * `mutually_exclusive`, `exactly_one_of` and `at_least_one_of` support `:above_all`

* Bugfix
  * param options for route_param DSL

* Deprecated
  * Maru.Parsers forked from plug

## v0.9.4 (2016-3-5)
* Enhancements
  * Allow param type definition in route_param.

* Bugfix
  * parse bool type error.

## v0.9.3 (2016-1-29)
* Enhancements
  * `maru.routers` is deprecated in favor of `maru.routes`
  * make poison 1.5 and 2.0 compatible

## v0.9.2 (2016-1-6)
* Enhancements
  * no longer keep nil value for optional params

## v0.9.1 (2016-1-4)
* Enhancements
  * update to elixir v1.2

* Bugfix
  * floats can be negative

## v0.9.0 (2015-11-29)
* Enhancements
  * import `Plug.Conn` for Maru.Router by default
  * reuse `text` `html` and `json` to make response

* Bugfix
  * `maru.routers` raise module undefined

* Deprecations
  * return NOT Plug.Conn struct by endpoint
  * custom response helpers: `assigns` `assign` `headers` `header` `content_type` `status` `present` in faver of functions of Plug.Conn.

## v0.8.5 (2015-11-4)
* Bugfix
  * params parser error within `Maru.Test`

## v0.8.4 (2015-10-14)
* Enhancements
  * support rename parameter using `source`
  * fork plug params for reusing request body

## v0.8.3 (2015-10-3)
* Enhancements
  * add paramer type `Json`
  * support parameter coercion using `coerce_with`

## v0.8.2 (2015-9-26)
* Documentation
  * add documentation
  * add ex_doc

* Deprecations
  * remove unused plug: Maru.Plugs.Forword

## v0.8.1 (2015-9-21)
* Enhancements
  * add `&Maru.Builder.Routers.generate/1` to generate endpoints details

## v0.8.0 (2015-9-20)
* Enhancements
  * Update to poison v1.5

## v0.7.2 (2015-9-20)
* Enhancements
  * remove deprecated functions
  * add build\_embedded and start\_permanent options
  * Support configure :port by system environment like {:system, "PORT"}
  * add `match` DSL to handle all method
  * Support HTTP 405 method not allowed
  * `maru.routers` task support `version extend` now

## v0.7.1 (2015-9-7)
* Bugfix
  * resolved shared params error

## v0.7.0 (2015-8-20)
* Enhancements
  * Support Plug v1.0

## v0.6.0 (2015-8-20)
* Enhancements
  * Support Plug v0.14

## v0.5.1 (2015-8-12)
* Enhancements
  * router extend support

* Bugfix
  * resolved deprecated functions warning

## v0.5.0 (2015-7-23)
* Enhancements
  * rewrite Versioning
  * return variable itself when present options hasn't `:with` key
  * add Maru.version

## v0.4.1 (2015-7-18)
* Enhancements
  * print log info when start maru http/https server
  * complex path like ":params" within namespace

## v0.4.0 (2015-7-9)
* Enhancements
  * Support Plug v0.13
  * add Maru.Test
  * redirect DSL

## v0.3.1 (2015-7-2)
* Enhancements
  * status DSL
  * rescue_from DSL
  * present DSL
  * Maru.Response procotol

* Deprecations
  * json/1, json/2, html/1, html/2, text/1, text/2 is deprecated in favor of returning data directly.
  * error/2 is deprecated in favor of rescue\_from/2 and rescue\_from/3.

* Bugfix
  * param value replaced by identical param keys in group [#5](https://github.com/falood/maru/issues/5).

## v0.3.0 (2015-6-2)
* Enhancements
  * Support Plug v0.12
  * Update to poison v1.4.0

## v0.2.10 (2015-6-1)
* Enhancements
  * Support reusable params by `use` DSL within `params`.
  * readd Maru.Middleware

* Bugfix
  * resolved params unused warning
