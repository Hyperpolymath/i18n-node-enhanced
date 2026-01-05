@@ocaml.doc("
  Catalog - Immutable translation catalog with structural sharing

  Catalogs are immutable data structures that hold translations.
  Updates create new catalogs sharing unchanged structure.
")

open Locale

@ocaml.doc("A translation value - either a simple string or plural forms")
type rec translationValue =
  | Simple(string)
  | Plural({
      zero: option<string>,
      one: option<string>,
      two: option<string>,
      few: option<string>,
      many: option<string>,
      other: string,
    })
  | Nested(translations)
and translations = Belt.Map.String.t<translationValue>

type metadata = {
  version: option<string>,
  lastModified: option<float>,
  source: option<string>,
}

@ocaml.doc("A catalog holds translations for a single locale")
type t = {
  locale: Locale.t,
  translations: translations,
  metadata: metadata,
}

@ocaml.doc("Create an empty catalog for a locale")
let empty = (locale: Locale.t): t => {
  locale,
  translations: Belt.Map.String.empty,
  metadata: {
    version: None,
    lastModified: None,
    source: None,
  },
}

@ocaml.doc("Get a translation by key, supporting dot notation")
let get = (catalog: t, key: string): option<translationValue> => {
  let parts = key->String.split(".")

  let rec traverse = (translations: translations, path: array<string>): option<translationValue> => {
    let len = Array.length(path)
    if len == 0 {
      None
    } else if len == 1 {
      path->Array.get(0)->Option.flatMap(single => translations->Belt.Map.String.get(single))
    } else {
      switch path->Array.get(0) {
      | None => None
      | Some(head) =>
        let rest = path->Array.sliceToEnd(~start=1)
        switch translations->Belt.Map.String.get(head) {
        | Some(Nested(nested)) => traverse(nested, rest)
        | _ => None
        }
      }
    }
  }

  traverse(catalog.translations, parts)
}

@ocaml.doc("Get a simple string translation")
let getString = (catalog: t, key: string): option<string> => {
  switch get(catalog, key) {
  | Some(Simple(s)) => Some(s)
  | Some(Plural({other})) => Some(other)
  | _ => None
  }
}

@ocaml.doc("Set a translation, returning a new catalog")
let set = (catalog: t, key: string, value: translationValue): t => {
  let parts = key->String.split(".")

  let rec updateNested = (
    translations: translations,
    path: array<string>,
    value: translationValue,
  ): translations => {
    let len = Array.length(path)
    if len == 0 {
      translations
    } else if len == 1 {
      switch path->Array.get(0) {
      | None => translations
      | Some(single) => translations->Belt.Map.String.set(single, value)
      }
    } else {
      switch path->Array.get(0) {
      | None => translations
      | Some(head) => {
          let rest = path->Array.sliceToEnd(~start=1)
          let existing = switch translations->Belt.Map.String.get(head) {
          | Some(Nested(nested)) => nested
          | _ => Belt.Map.String.empty
          }
          let updated = updateNested(existing, rest, value)
          translations->Belt.Map.String.set(head, Nested(updated))
        }
      }
    }
  }

  {
    ...catalog,
    translations: updateNested(catalog.translations, parts, value),
    metadata: {
      ...catalog.metadata,
      lastModified: Some(Js.Date.now()),
    },
  }
}

@ocaml.doc("Check if a key exists")
let has = (catalog: t, key: string): bool => get(catalog, key)->Option.isSome

@ocaml.doc("Get all keys in the catalog (flattened)")
let keys = (catalog: t): array<string> => {
  let rec collect = (translations: translations, prefix: string): array<string> => {
    translations
    ->Belt.Map.String.toArray
    ->Array.flatMap(((key, value)) => {
      let fullKey = prefix == "" ? key : `${prefix}.${key}`
      switch value {
      | Simple(_) | Plural(_) => [fullKey]
      | Nested(nested) => collect(nested, fullKey)
      }
    })
  }
  collect(catalog.translations, "")
}

@ocaml.doc("Merge two catalogs, with the second taking precedence")
let merge = (base: t, overlay: t): t => {
  let rec mergeTranslations = (a: translations, b: translations): translations => {
    let allKeys =
      Array.concat(
        a->Belt.Map.String.keysToArray,
        b->Belt.Map.String.keysToArray,
      )->Belt.Set.String.fromArray->Belt.Set.String.toArray

    allKeys->Array.reduce(Belt.Map.String.empty, (acc, key) => {
      let value = switch (a->Belt.Map.String.get(key), b->Belt.Map.String.get(key)) {
      | (_, Some(v)) => v
      | (Some(v), None) => v
      | (None, None) => Simple("") // unreachable
      }
      acc->Belt.Map.String.set(key, value)
    })
  }

  {
    locale: overlay.locale,
    translations: mergeTranslations(base.translations, overlay.translations),
    metadata: overlay.metadata,
  }
}

@ocaml.doc("Parse a catalog from JSON")
let fromJson = (locale: Locale.t, json: Js.Json.t): result<t, string> => {
  let rec parseValue = (json: Js.Json.t): option<translationValue> => {
    switch Js.Json.classify(json) {
    | Js.Json.JSONString(s) => Some(Simple(s))
    | Js.Json.JSONObject(obj) => {
        // Check if it's plural forms or nested
        let hasPlural = obj->Js.Dict.get("other")->Option.isSome
        if hasPlural {
          let getStr = key =>
            obj->Js.Dict.get(key)->Option.flatMap(v =>
              switch Js.Json.classify(v) {
              | Js.Json.JSONString(s) => Some(s)
              | _ => None
              }
            )
          switch getStr("other") {
          | Some(other) =>
            Some(
              Plural({
                zero: getStr("zero"),
                one: getStr("one"),
                two: getStr("two"),
                few: getStr("few"),
                many: getStr("many"),
                other,
              }),
            )
          | None => None
          }
        } else {
          // Nested translations
          let nested =
            obj
            ->Js.Dict.entries
            ->Array.reduce(Belt.Map.String.empty, (acc, (key, value)) => {
              switch parseValue(value) {
              | Some(v) => acc->Belt.Map.String.set(key, v)
              | None => acc
              }
            })
          Some(Nested(nested))
        }
      }
    | _ => None
    }
  }

  switch Js.Json.classify(json) {
  | Js.Json.JSONObject(obj) => {
      let translations =
        obj
        ->Js.Dict.entries
        ->Array.reduce(Belt.Map.String.empty, (acc, (key, value)) => {
          switch parseValue(value) {
          | Some(v) => acc->Belt.Map.String.set(key, v)
          | None => acc
          }
        })
      Ok({
        locale,
        translations,
        metadata: {
          version: None,
          lastModified: Some(Js.Date.now()),
          source: None,
        },
      })
    }
  | _ => Error("Expected JSON object at root")
  }
}

@ocaml.doc("Serialize a catalog to JSON")
let toJson = (catalog: t): Js.Json.t => {
  let rec valueToJson = (value: translationValue): Js.Json.t => {
    switch value {
    | Simple(s) => Js.Json.string(s)
    | Plural({zero, one, two, few, many, other}) => {
        let obj = Js.Dict.empty()
        zero->Option.forEach(v => obj->Js.Dict.set("zero", Js.Json.string(v)))
        one->Option.forEach(v => obj->Js.Dict.set("one", Js.Json.string(v)))
        two->Option.forEach(v => obj->Js.Dict.set("two", Js.Json.string(v)))
        few->Option.forEach(v => obj->Js.Dict.set("few", Js.Json.string(v)))
        many->Option.forEach(v => obj->Js.Dict.set("many", Js.Json.string(v)))
        obj->Js.Dict.set("other", Js.Json.string(other))
        Js.Json.object_(obj)
      }
    | Nested(nested) => {
        let obj = Js.Dict.empty()
        nested->Belt.Map.String.forEach((key, value) => {
          obj->Js.Dict.set(key, valueToJson(value))
        })
        Js.Json.object_(obj)
      }
    }
  }

  let obj = Js.Dict.empty()
  catalog.translations->Belt.Map.String.forEach((key, value) => {
    obj->Js.Dict.set(key, valueToJson(value))
  })
  Js.Json.object_(obj)
}
