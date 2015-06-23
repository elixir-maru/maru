## Changelog

## v0.3.1-dev
* Enhancements
  * status DSL
  * rescue_from DSL
  * Maru.Response procotol

* Deprecations
  * json/1, json/2, html/1, html/2, text/1, text/2 is deprecated in favor of returning data directly.
  * error/2 is deprecated in favor of rescue_from/2 and rescue_from/3.

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
