## Changelog

## v0.8.4-dev

## v0.8.3 (2015-10-03)
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
