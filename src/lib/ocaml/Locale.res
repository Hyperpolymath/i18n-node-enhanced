@@ocaml.doc("
  Locale - Type-safe locale handling for polyglot-i18n

  Locales are validated at construction time. Invalid locales
  cannot exist in the type system.
")

module LanguageTag = {
  @ocaml.doc("BCP 47 language tag components")
  type t = {
    language: string,
    script: option<string>,
    region: option<string>,
    variants: array<string>,
  }

  let languagePattern = %re("/^[a-z]{2,3}$/i")
  let scriptPattern = %re("/^[A-Z][a-z]{3}$/")
  let regionPattern = %re("/^[A-Z]{2}$|^[0-9]{3}$/")

  let parse = (tag: string): option<t> => {
    let parts = tag->String.split("-")
    let len = Array.length(parts)

    if len == 0 {
      None
    } else {
      switch parts->Array.get(0) {
      | None => None
      | Some(lang) if languagePattern->RegExp.test(lang) => {
          let rest = parts->Array.slice(~start=1, ~end=len)
          let script = rest->Array.get(0)->Option.flatMap(s =>
            scriptPattern->RegExp.test(s) ? Some(s) : None
          )
          let regionIdx = script->Option.isSome ? 1 : 0
          let region = rest->Array.get(regionIdx)->Option.flatMap(r =>
            regionPattern->RegExp.test(r) ? Some(r) : None
          )
          let variantIdx = regionIdx + (region->Option.isSome ? 1 : 0)
          let variants = rest->Array.slice(~start=variantIdx, ~end=Array.length(rest))

          Some({
            language: lang->String.toLowerCase,
            script,
            region,
            variants,
          })
        }
      | _ => None
      }
    }
  }

  let toString = (tag: t): string => {
    let parts = [tag.language]
    tag.script->Option.forEach(s => parts->Array.push(s)->ignore)
    tag.region->Option.forEach(r => parts->Array.push(r)->ignore)
    tag.variants->Array.forEach(v => parts->Array.push(v)->ignore)
    parts->Array.join("-")
  }
}

@ocaml.doc("A validated locale identifier")
type t = {
  tag: LanguageTag.t,
  raw: string,
}

@ocaml.doc("Create a locale from a string. Returns None if invalid.")
let fromString = (s: string): option<t> => {
  LanguageTag.parse(s)->Option.map(tag => {
    tag,
    raw: LanguageTag.toString(tag),
  })
}

@ocaml.doc("Create a locale, raising if invalid. Use only with known-good values.")
let fromStringExn = (s: string): t => {
  switch fromString(s) {
  | Some(locale) => locale
  | None => Js.Exn.raiseError(`Invalid locale: ${s}`)
  }
}

@ocaml.doc("Get the canonical string representation")
let toString = (locale: t): string => locale.raw

@ocaml.doc("Get the language component (e.g., 'en' from 'en-US')")
let language = (locale: t): string => locale.tag.language

@ocaml.doc("Get the region component if present")
let region = (locale: t): option<string> => locale.tag.region

@ocaml.doc("Get the script component if present")
let script = (locale: t): option<string> => locale.tag.script

@ocaml.doc("Check if two locales are equal")
let eq = (a: t, b: t): bool => a.raw == b.raw

@ocaml.doc("Compare two locales for ordering")
let compare = (a: t, b: t): int => String.compare(a.raw, b.raw)->Float.toInt

@ocaml.doc("Get the parent locale (e.g., 'en' from 'en-US')")
let parent = (locale: t): option<t> => {
  switch (locale.tag.region, locale.tag.script) {
  | (Some(_), _) => fromString(locale.tag.language)
  | (None, Some(_)) => fromString(locale.tag.language)
  | (None, None) => None
  }
}

@ocaml.doc("Build a fallback chain for a locale")
let fallbackChain = (locale: t): array<t> => {
  let rec build = (current: t, acc: array<t>) => {
    let newAcc = Array.concat(acc, [current])
    switch parent(current) {
    | Some(p) => build(p, newAcc)
    | None => newAcc
    }
  }
  build(locale, [])
}

@ocaml.doc("The default locale (English)")
let defaultLocale: t = fromStringExn("en")

module Set = Belt.Set.String
module Map = Belt.Map.String
