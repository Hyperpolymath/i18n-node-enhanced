// Stemmer - Word root extraction for translation memory
// SPDX-License-Identifier: AGPL-3.0-or-later

type locale =
  | English
  | German
  | French
  | Spanish
  | Italian
  | Portuguese
  | Dutch
  | Russian

type t = {locale: locale}

let make = locale => {locale: locale}

let fromString = s => {
  let base = s->String.split("-")->Array.get(0)->Option.getOr(s)->String.toLowerCase
  let locale = switch base {
  | "en" => English
  | "de" => German
  | "fr" => French
  | "es" => Spanish
  | "it" => Italian
  | "pt" => Portuguese
  | "nl" => Dutch
  | "ru" => Russian
  | _ => English
  }
  {locale: locale}
}

let supportedLocales = ["en", "de", "fr", "es", "it", "pt", "nl", "ru"]

// Check if string contains vowel
let hasVowel = s => {
  let vowels = ["a", "e", "i", "o", "u"]
  s->String.split("")->Array.some(c => vowels->Array.includes(c))
}

// English Porter Stemmer (simplified)
let stemEnglish = (word: string): string => {
  let s = ref(word->String.toLowerCase)

  // Step 1a
  if s.contents->String.endsWith("sses") {
    s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 2)
  } else if s.contents->String.endsWith("ies") {
    s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 2)
  } else if (
    s.contents->String.endsWith("s") &&
    !(s.contents->String.endsWith("ss")) &&
    String.length(s.contents) > 3
  ) {
    s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 1)
  }

  // Step 1b
  if s.contents->String.endsWith("eed") {
    if String.length(s.contents) > 4 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 1)
    }
  } else if s.contents->String.endsWith("ed") {
    let stem = s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 2)
    if hasVowel(stem) {
      s := stem
    }
  } else if s.contents->String.endsWith("ing") {
    let stem = s.contents->String.slice(~start=0, ~end=String.length(s.contents) - 3)
    if hasVowel(stem) {
      s := stem
    }
  }

  // Step 2: common suffix replacements
  let suffixes = [
    ("ational", "ate"),
    ("tional", "tion"),
    ("enci", "ence"),
    ("anci", "ance"),
    ("izer", "ize"),
    ("ization", "ize"),
    ("ation", "ate"),
    ("ator", "ate"),
    ("alism", "al"),
    ("iveness", "ive"),
    ("fulness", "ful"),
    ("ousness", "ous"),
    ("aliti", "al"),
    ("iviti", "ive"),
    ("biliti", "ble"),
  ]

  suffixes->Array.forEach(((suffix, replacement)) => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s :=
        s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix)) ++
        replacement
    }
  })

  // Step 3
  let step3 = [("icate", "ic"), ("ative", ""), ("alize", "al"), ("iciti", "ic"), ("ical", "ic"), ("ful", ""), ("ness", "")]

  step3->Array.forEach(((suffix, replacement)) => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s :=
        s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix)) ++
        replacement
    }
  })

  s.contents
}

// German Stemmer
let stemGerman = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = ["erin", "ern", "em", "en", "er", "es", "e", "s"]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// French Stemmer
let stemFrench = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = [
    "issements",
    "issement",
    "atrices",
    "atrice",
    "ateur",
    "ations",
    "ation",
    "ences",
    "ence",
    "ments",
    "ment",
    "ités",
    "ité",
    "ives",
    "ive",
    "eaux",
    "aux",
    "euses",
    "euse",
    "eux",
    "es",
    "é",
    "e",
  ]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// Spanish Stemmer
let stemSpanish = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = [
    "amientos",
    "imientos",
    "amiento",
    "imiento",
    "aciones",
    "ación",
    "adoras",
    "adores",
    "adora",
    "ador",
    "ancias",
    "ancia",
    "antes",
    "ante",
    "ables",
    "able",
    "ibles",
    "ible",
    "istas",
    "ista",
    "mente",
    "idad",
    "ivos",
    "iva",
    "ivo",
    "osas",
    "oso",
    "osa",
    "es",
    "os",
    "as",
    "a",
    "o",
  ]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// Italian Stemmer
let stemItalian = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = ["amento", "amenti", "imento", "imenti", "azione", "azioni", "atore", "atori", "mente", "ità", "ivo", "iva", "ivi", "ive", "oso", "osa", "osi", "ose", "abile", "ibile", "ante", "ente", "i", "e", "a", "o"]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// Portuguese Stemmer
let stemPortuguese = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = ["amentos", "amento", "imentos", "imento", "ações", "ação", "adores", "ador", "mente", "idade", "ivo", "iva", "oso", "osa", "ável", "ível", "ante", "ente", "es", "os", "as", "a", "o"]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// Dutch Stemmer
let stemDutch = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = ["heden", "heid", "ingen", "ing", "elijk", "baar", "en", "e"]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

// Russian Stemmer (simplified)
let stemRussian = (word: string): string => {
  let s = ref(word->String.toLowerCase)
  let suffixes = ["ость", "ости", "ние", "ния", "ами", "ями", "ов", "ев", "ей", "ах", "ях", "ом", "ем", "ий", "ый", "ая", "ое", "ие", "ые", "а", "я", "ы", "и", "у", "ю", "е", "о"]

  suffixes->Array.forEach(suffix => {
    if s.contents->String.endsWith(suffix) && String.length(s.contents) > String.length(suffix) + 2 {
      s := s.contents->String.slice(~start=0, ~end=String.length(s.contents) - String.length(suffix))
    }
  })

  s.contents
}

let stem = (t, word) => {
  switch t.locale {
  | English => stemEnglish(word)
  | German => stemGerman(word)
  | French => stemFrench(word)
  | Spanish => stemSpanish(word)
  | Italian => stemItalian(word)
  | Portuguese => stemPortuguese(word)
  | Dutch => stemDutch(word)
  | Russian => stemRussian(word)
  }
}

let stemWords = (t, words) => words->Array.map(w => stem(t, w))

let stemText = (t, text) => {
  // Split by whitespace, stem words, rejoin
  text
  ->String.split(" ")
  ->Array.map(word => {
    // Check if it's actually a word (has letters)
    if %re("/[a-zA-Zа-яА-Я]/")->RegExp.test(word) {
      stem(t, word)
    } else {
      word
    }
  })
  ->Array.join(" ")
}
