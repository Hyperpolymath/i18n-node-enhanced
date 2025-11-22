/* i18n ReScript Bindings */

module I18nConfig = {
  type t = {
    locales: array<string>,
    defaultLocale: string,
    directory: string,
    updateFiles: bool,
    autoReload: bool,
    syncFiles: bool,
    objectNotation: bool,
    cookie: option<string>,
    queryParameter: option<string>,
    header: string,
    retryInDefaultLocale: bool,
  }

  let make = (
    ~locales,
    ~defaultLocale="en",
    ~directory="./locales",
    ~updateFiles=true,
    ~autoReload=false,
    ~syncFiles=false,
    ~objectNotation=false,
    ~cookie=?,
    ~queryParameter=?,
    ~header="accept-language",
    ~retryInDefaultLocale=false,
    ()
  ) => {
    locales: locales,
    defaultLocale: defaultLocale,
    directory: directory,
    updateFiles: updateFiles,
    autoReload: autoReload,
    syncFiles: syncFiles,
    objectNotation: objectNotation,
    cookie: cookie,
    queryParameter: queryParameter,
    header: header,
    retryInDefaultLocale: retryInDefaultLocale,
  }
}

module I18n = {
  type t

  @module("i18n") @new
  external make: I18nConfig.t => t = "I18n"

  @send external configure: (t, I18nConfig.t) => unit = "configure"

  @send external __: (t, string) => string = "__"
  @send external __WithArgs: (t, string, array<'a>) => string = "__"

  @send external __n: (t, string, string, int) => string = "__n"

  @send external __mf: (t, string, Js.Dict.t<'a>) => string = "__mf"

  @send external __l: (t, string) => array<string> = "__l"

  @send external __h: (t, string) => Js.Dict.t<string> = "__h"

  @send external setLocale: (t, string) => string = "setLocale"
  @send external getLocale: t => string = "getLocale"
  @send external getLocales: t => array<string> = "getLocales"

  @send external getCatalog: t => Js.Dict.t<'a> = "getCatalog"
  @send external getCatalogForLocale: (t, string) => Js.Dict.t<'a> = "getCatalog"

  @send external addLocale: (t, string) => unit = "addLocale"
  @send external removeLocale: (t, string) => unit = "removeLocale"

  // Express middleware
  type req
  type res
  type next = unit => unit

  @send external init: (t, req, res, next) => unit = "init"
}

// Usage example module
module Example = {
  let config = I18nConfig.make(
    ~locales=["en", "de", "fr"],
    ~defaultLocale="en",
    ~directory="./locales",
    ~objectNotation=true,
    ()
  )

  let i18n = I18n.make(config)

  let translate = (key: string): string => {
    i18n->I18n.__(key)
  }

  let translateWithArgs = (key: string, args: array<'a>): string => {
    i18n->I18n.__WithArgs(key, args)
  }

  let translatePlural = (singular: string, plural: string, count: int): string => {
    i18n->I18n.__n(singular, plural, count)
  }

  let setLanguage = (locale: string): string => {
    i18n->I18n.setLocale(locale)
  }

  let getCurrentLanguage = (): string => {
    i18n->I18n.getLocale()
  }
}
