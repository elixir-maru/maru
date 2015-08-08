## Changelog

## v0.5.1-dev
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
