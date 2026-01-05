@@ocaml.doc("
  I18n - Main API for polyglot-i18n

  A type-safe, immutable internationalization library.

  Features:
  - Compile-time locale validation
  - Immutable catalogs with structural sharing
  - WASM-accelerated plural rules
  - Mustache and sprintf interpolation
")

open Locale
open Catalog
open Plural

@ocaml.doc("Configuration for an I18n instance")
type config = {
  locales: array<Locale.t>,
  defaultLocale: Locale.t,
  fallbacks: Belt.Map.String.t<Locale.t>,
  objectNotation: bool,
  missingKeyHandler: option<(Locale.t, string) => string>,
}

@ocaml.doc("An I18n instance holds catalogs and configuration")
type t = {
  config: config,
  catalogs: Belt.Map.String.t<Catalog.t>,
  currentLocale: Locale.t,
}

module Config = {
  type builder = {
    mutable locales: array<string>,
    mutable defaultLocale: option<string>,
    mutable fallbacks: array<(string, string)>,
    mutable objectNotation: bool,
    mutable missingKeyHandler: option<(Locale.t, string) => string>,
  }

  let make = (): builder => {
    locales: [],
    defaultLocale: None,
    fallbacks: [],
    objectNotation: false,
    missingKeyHandler: None,
  }

  let withLocales = (builder: builder, locales: array<string>): builder => {
    builder.locales = locales
    builder
  }

  let withDefaultLocale = (builder: builder, locale: string): builder => {
    builder.defaultLocale = Some(locale)
    builder
  }

  let withFallback = (builder: builder, from: string, to_: string): builder => {
    builder.fallbacks = Array.concat(builder.fallbacks, [(from, to_)])
    builder
  }

  let withObjectNotation = (builder: builder, enabled: bool): builder => {
    builder.objectNotation = enabled
    builder
  }

  let withMissingKeyHandler = (builder: builder, handler: (Locale.t, string) => string): builder => {
    builder.missingKeyHandler = Some(handler)
    builder
  }

  let build = (builder: builder): result<config, string> => {
    let locales =
      builder.locales
      ->Array.filterMap(Locale.fromString)

    if Array.length(locales) == 0 {
      Error("At least one valid locale is required")
    } else {
      let defaultLocale = switch builder.defaultLocale {
      | Some(s) => Locale.fromString(s)
      | None => locales->Array.get(0)
      }

      switch defaultLocale {
      | None => Error("Invalid default locale")
      | Some(defaultLocale) =>
        let fallbacks =
          builder.fallbacks
          ->Array.reduce(Belt.Map.String.empty, (acc, (from, to_)) => {
            switch (Locale.fromString(from), Locale.fromString(to_)) {
            | (Some(f), Some(t)) => acc->Belt.Map.String.set(Locale.toString(f), t)
            | _ => acc
            }
          })

        Ok({
          locales,
          defaultLocale,
          fallbacks,
          objectNotation: builder.objectNotation,
          missingKeyHandler: builder.missingKeyHandler,
        })
      }
    }
  }
}

@ocaml.doc("Create a new I18n instance with the given configuration")
let make = (config: config): t => {
  // Initialize empty catalogs for each locale
  let catalogs =
    config.locales->Array.reduce(Belt.Map.String.empty, (acc, locale) => {
      acc->Belt.Map.String.set(Locale.toString(locale), Catalog.empty(locale))
    })

  {
    config,
    catalogs,
    currentLocale: config.defaultLocale,
  }
}

@ocaml.doc("Create from a builder")
let fromBuilder = (builder: Config.builder): result<t, string> => {
  Config.build(builder)->Result.map(make)
}

@ocaml.doc("Get the current locale")
let getLocale = (i18n: t): Locale.t => i18n.currentLocale

@ocaml.doc("Set the current locale, returning a new instance")
let setLocale = (i18n: t, locale: Locale.t): t => {
  // Check if locale is configured, fall back if not
  let resolvedLocale = if i18n.config.locales->Array.some(l => Locale.eq(l, locale)) {
    locale
  } else {
    // Try fallback
    switch i18n.config.fallbacks->Belt.Map.String.get(Locale.toString(locale)) {
    | Some(fallback) => fallback
    | None => i18n.config.defaultLocale
    }
  }

  {...i18n, currentLocale: resolvedLocale}
}

@ocaml.doc("Set locale by string, returning a new instance")
let setLocaleString = (i18n: t, locale: string): t => {
  switch Locale.fromString(locale) {
  | Some(l) => setLocale(i18n, l)
  | None => i18n
  }
}

@ocaml.doc("Get the catalog for a locale")
let getCatalog = (i18n: t, locale: Locale.t): option<Catalog.t> => {
  i18n.catalogs->Belt.Map.String.get(Locale.toString(locale))
}

@ocaml.doc("Load translations into a catalog")
let loadTranslations = (i18n: t, locale: Locale.t, json: Js.Json.t): result<t, string> => {
  Catalog.fromJson(locale, json)->Result.map(catalog => {
    let key = Locale.toString(locale)
    let existingCatalog = i18n.catalogs->Belt.Map.String.get(key)->Option.getOr(Catalog.empty(locale))
    let mergedCatalog = Catalog.merge(existingCatalog, catalog)

    {
      ...i18n,
      catalogs: i18n.catalogs->Belt.Map.String.set(key, mergedCatalog),
    }
  })
}

@ocaml.doc("Interpolation helpers")
module Interpolate = {
  // Mustache-style: {{variable}}
  let mustachePattern = %re("/\{\{(\w+)\}\}/g")

  // sprintf-style: %s, %d, %f, etc.
  let sprintfPattern = %re("/%([sdfo%])/g")

  let mustache = (template: string, values: dict<string>): string => {
    template->String.unsafeReplaceRegExpBy1(mustachePattern, (~match, ~group1, ~offset as _, ~input as _) => {
      // group1 contains the variable name (captured by \w+)
      values->Dict.get(group1)->Option.getOr(match)
    })
  }

  let sprintf = (template: string, args: array<string>): string => {
    let index = ref(0)
    template->String.unsafeReplaceRegExpBy1(sprintfPattern, (~match, ~group1 as _, ~offset as _, ~input as _) => {
      switch match {
      | "%%" => "%"
      | _ =>
        let result = args->Array.get(index.contents)->Option.getOr(match)
        index := index.contents + 1
        result
      }
    })
  }
}

@ocaml.doc("Translate a key")
let translate = (i18n: t, key: string): string => {
  let locale = i18n.currentLocale

  // Build lookup chain: current locale -> fallbacks -> default
  let localeChain = {
    let chain = [locale]
    // Add fallback if configured
    switch i18n.config.fallbacks->Belt.Map.String.get(Locale.toString(locale)) {
    | Some(fallback) => Array.concat(chain, [fallback])
    | None => chain
    }
  }
  let chain = if !(localeChain->Array.some(l => Locale.eq(l, i18n.config.defaultLocale))) {
    Array.concat(localeChain, [i18n.config.defaultLocale])
  } else {
    localeChain
  }

  // Try each locale in the chain
  let result =
    chain->Array.reduce(None, (acc, currentLocale) => {
      switch acc {
      | Some(_) => acc
      | None =>
        i18n.catalogs
        ->Belt.Map.String.get(Locale.toString(currentLocale))
        ->Option.flatMap(catalog => Catalog.getString(catalog, key))
      }
    })

  switch result {
  | Some(translation) => translation
  | None =>
    // Handle missing key
    switch i18n.config.missingKeyHandler {
    | Some(handler) => handler(locale, key)
    | None => key // Return key itself as fallback
    }
  }
}

@ocaml.doc("Translate with mustache interpolation")
let translateWith = (i18n: t, key: string, values: Js.Dict.t<string>): string => {
  translate(i18n, key)->Interpolate.mustache(values)
}

@ocaml.doc("Translate with sprintf arguments")
let translateArgs = (i18n: t, key: string, args: array<string>): string => {
  translate(i18n, key)->Interpolate.sprintf(args)
}

@ocaml.doc("Translate with plural support")
let translatePlural = (
  i18n: t,
  singular: string,
  plural: string,
  count: float,
): string => {
  let locale = i18n.currentLocale
  let category = Plural.selectForLocale(count, locale)

  // Try to get plural forms from catalog
  let catalogResult =
    i18n.catalogs
    ->Belt.Map.String.get(Locale.toString(locale))
    ->Option.flatMap(catalog => Catalog.get(catalog, singular))

  let template = switch catalogResult {
  | Some(Plural({zero, one, two, few, many, other})) =>
    switch category {
    | Zero => zero->Option.getOr(other)
    | One => one->Option.getOr(other)
    | Two => two->Option.getOr(other)
    | Few => few->Option.getOr(other)
    | Many => many->Option.getOr(other)
    | Other => other
    }
  | Some(Simple(s)) => s
  | _ =>
    // Fall back to singular/plural strings
    switch category {
    | One => singular
    | _ => plural
    }
  }

  // Replace count placeholder
  template->String.replaceRegExp(%re("/%[sd]/"), Float.toString(count))
}

@ocaml.doc("Shorthand: __")
let __ = translate

@ocaml.doc("Shorthand: __n for plurals")
let __n = translatePlural

@ocaml.doc("Get all configured locales")
let getLocales = (i18n: t): array<Locale.t> => i18n.config.locales

@ocaml.doc("Get the default locale")
let getDefaultLocale = (i18n: t): Locale.t => i18n.config.defaultLocale

@ocaml.doc("Check if a translation key exists")
let hasKey = (i18n: t, key: string): bool => {
  let locale = i18n.currentLocale
  i18n.catalogs
  ->Belt.Map.String.get(Locale.toString(locale))
  ->Option.map(catalog => Catalog.has(catalog, key))
  ->Option.getOr(false)
}

@ocaml.doc("Get all keys for the current locale")
let getAllKeys = (i18n: t): array<string> => {
  let locale = i18n.currentLocale
  i18n.catalogs
  ->Belt.Map.String.get(Locale.toString(locale))
  ->Option.map(Catalog.keys)
  ->Option.getOr([])
}

@ocaml.doc("Export current catalog as JSON")
let exportCatalog = (i18n: t, locale: Locale.t): option<Js.Json.t> => {
  i18n.catalogs
  ->Belt.Map.String.get(Locale.toString(locale))
  ->Option.map(Catalog.toJson)
}
