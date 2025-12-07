@@ocaml.doc("
  Plural - CLDR plural rule evaluation

  This module provides plural category selection based on CLDR rules.
  The implementation can use either:
  - Pure ReScript fallback (portable)
  - WASM accelerated (10x faster, optional)
")

@ocaml.doc("CLDR plural categories")
type category =
  | Zero
  | One
  | Two
  | Few
  | Many
  | Other

let categoryToString = (cat: category): string => {
  switch cat {
  | Zero => "zero"
  | One => "one"
  | Two => "two"
  | Few => "few"
  | Many => "many"
  | Other => "other"
  }
}

let categoryFromString = (s: string): option<category> => {
  switch s {
  | "zero" => Some(Zero)
  | "one" => Some(One)
  | "two" => Some(Two)
  | "few" => Some(Few)
  | "many" => Some(Many)
  | "other" => Some(Other)
  | _ => None
  }
}

@ocaml.doc("Operands for CLDR plural rules")
type operands = {
  n: float, // absolute value of the source number
  i: float, // integer digits of n
  v: int, // number of visible fraction digits
  w: int, // number of visible fraction digits without trailing zeros
  f: float, // visible fractional digits
  t: float, // visible fractional digits without trailing zeros
  c: int, // compact decimal exponent value
  e: int, // synonym for c
}

let getOperands = (n: float): operands => {
  let absN = Js.Math.abs_float(n)
  let str = Float.toString(absN)
  let parts = str->String.split(".")

  let intPart = parts->Array.get(0)->Option.getOr("0")
  let fracPart = parts->Array.get(1)->Option.getOr("")

  let i = Float.fromString(intPart)->Option.getOr(0.0)
  let v = String.length(fracPart)
  let fracWithoutZeros = fracPart->String.replaceRegExp(%re("/0+$/"), "")
  let w = String.length(fracWithoutZeros)
  let f = Float.fromString(fracPart)->Option.getOr(0.0)
  let t = Float.fromString(fracWithoutZeros)->Option.getOr(0.0)

  {n: absN, i, v, w, f, t, c: 0, e: 0}
}

@ocaml.doc("
  WASM bindings for accelerated plural evaluation.
  Falls back to ReScript implementation if WASM not loaded.
")
module Wasm = {
  type wasmModule

  @module("./plural_engine.wasm") @val
  external wasmModule: option<wasmModule> = "default"

  @send external evaluate: (wasmModule, float, string) => string = "evaluate_plural"

  let isAvailable = (): bool => wasmModule->Option.isSome

  let evaluateCategory = (n: float, locale: string): option<category> => {
    wasmModule->Option.flatMap(wasm => {
      let result = wasm->evaluate(n, locale)
      categoryFromString(result)
    })
  }
}

@ocaml.doc("
  Pure ReScript plural rule implementations.
  Based on CLDR plural rules.
")
module Rules = {
  // English: one for 1, other for everything else (integers only)
  let en = (op: operands): category => {
    if op.i == 1.0 && op.v == 0 {
      One
    } else {
      Other
    }
  }

  // German: same as English
  let de = en

  // French: one for 0 and 1, other for everything else
  let fr = (op: operands): category => {
    if op.i == 0.0 || op.i == 1.0 {
      One
    } else {
      Other
    }
  }

  // Russian: complex rules
  let ru = (op: operands): category => {
    let mod10 = mod_float(op.i, 10.0)
    let mod100 = mod_float(op.i, 100.0)

    if op.v == 0 {
      if mod10 == 1.0 && mod100 != 11.0 {
        One
      } else if mod10 >= 2.0 && mod10 <= 4.0 && (mod100 < 12.0 || mod100 > 14.0) {
        Few
      } else if mod10 == 0.0 || (mod10 >= 5.0 && mod10 <= 9.0) || (mod100 >= 11.0 && mod100 <= 14.0) {
        Many
      } else {
        Other
      }
    } else {
      Other
    }
  }

  // Arabic: complex rules with zero, one, two, few, many
  let ar = (op: operands): category => {
    let mod100 = mod_float(op.n, 100.0)

    if op.n == 0.0 {
      Zero
    } else if op.n == 1.0 {
      One
    } else if op.n == 2.0 {
      Two
    } else if mod100 >= 3.0 && mod100 <= 10.0 {
      Few
    } else if mod100 >= 11.0 && mod100 <= 99.0 {
      Many
    } else {
      Other
    }
  }

  // Polish: few and many
  let pl = (op: operands): category => {
    let mod10 = mod_float(op.i, 10.0)
    let mod100 = mod_float(op.i, 100.0)

    if op.v == 0 {
      if op.i == 1.0 {
        One
      } else if mod10 >= 2.0 && mod10 <= 4.0 && (mod100 < 12.0 || mod100 > 14.0) {
        Few
      } else if op.i != 1.0 && (mod10 == 0.0 || mod10 == 1.0) ||
                (mod10 >= 5.0 && mod10 <= 9.0) ||
                (mod100 >= 12.0 && mod100 <= 14.0) {
        Many
      } else {
        Other
      }
    } else {
      Other
    }
  }

  // Japanese, Chinese, Korean: no plural forms
  let ja = (_op: operands): category => Other
  let zh = ja
  let ko = ja
}

@ocaml.doc("Get the plural rule function for a locale")
let getRuleForLocale = (locale: string): option<operands => category> => {
  let lang = locale->String.split("-")->Array.get(0)->Option.getOr(locale)->String.toLowerCase

  switch lang {
  | "en" => Some(Rules.en)
  | "de" => Some(Rules.de)
  | "fr" => Some(Rules.fr)
  | "ru" => Some(Rules.ru)
  | "ar" => Some(Rules.ar)
  | "pl" => Some(Rules.pl)
  | "ja" => Some(Rules.ja)
  | "zh" => Some(Rules.zh)
  | "ko" => Some(Rules.ko)
  | _ => None
  }
}

@ocaml.doc("
  Select the plural category for a number in a locale.
  Uses WASM if available, falls back to ReScript.
")
let select = (n: float, locale: string): category => {
  // Try WASM first
  switch Wasm.evaluateCategory(n, locale) {
  | Some(cat) => cat
  | None =>
    // Fall back to ReScript implementation
    switch getRuleForLocale(locale) {
    | Some(rule) => rule(getOperands(n))
    | None => Other // Unknown locale defaults to Other
    }
  }
}

@ocaml.doc("Select plural category using a Locale.t")
let selectForLocale = (n: float, locale: Locale.t): category => {
  select(n, Locale.toString(locale))
}
