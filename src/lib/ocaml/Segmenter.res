// Segmenter - Sentence and word boundary detection
// SPDX-License-Identifier: AGPL-3.0-or-later

type segment = {
  text: string,
  start: int,
  end_: int,
}

type t = {locale: string}

let make = (locale: Locale.t) => {
  locale: Locale.toString(locale),
}

let fromString = (s: string) => {
  let base = s->String.split("-")->Array.get(0)->Option.getOr(s)->String.toLowerCase
  {locale: base}
}

// CJK language check
let isCJK = locale => {
  switch locale {
  | "ja" | "zh" | "ko" => true
  | _ => false
  }
}

let segmentSentences = (t, text: string): array<string> => {
  if isCJK(t.locale) {
    // CJK: split on sentence-ending punctuation
    let result = []
    let current = ref("")

    text->String.split("")->Array.forEach(c => {
      current := current.contents ++ c
      if c == "。" || c == "！" || c == "？" || c == "." || c == "!" || c == "?" {
        let trimmed = current.contents->String.trim
        if trimmed != "" {
          result->Array.push(trimmed)->ignore
        }
        current := ""
      }
    })

    let remaining = current.contents->String.trim
    if remaining != "" {
      result->Array.push(remaining)->ignore
    }

    result
  } else {
    // Western languages - more sophisticated splitting
    // Split on . ! ? followed by space and capital or end
    let sentences = []
    let current = ref("")
    let chars = text->String.split("")
    let len = Array.length(chars)

    for i in 0 to len - 1 {
      let c = chars->Array.getUnsafe(i)
      current := current.contents ++ c

      if c == "." || c == "!" || c == "?" || c == "。" || c == "！" || c == "？" {
        // Check if end of sentence
        let nextChar = if i + 1 < len { chars->Array.get(i + 1) } else { None }
        let nextNext = if i + 2 < len { chars->Array.get(i + 2) } else { None }

        let isEnd = switch (nextChar, nextNext) {
        | (None, _) => true
        | (Some(" "), Some(nc)) => {
            // Check if uppercase (simple ASCII check)
            switch nc->String.charCodeAt(0) {
            | Some(code) => code >= 65 && code <= 90
            | None => false
            }
          }
        | (Some(" "), None) => true
        | (Some("\n"), _) => true
        | _ => false
        }

        if isEnd {
          let trimmed = current.contents->String.trim
          if trimmed != "" {
            sentences->Array.push(trimmed)->ignore
          }
          current := ""
        }
      }
    }

    let remaining = current.contents->String.trim
    if remaining != "" {
      sentences->Array.push(remaining)->ignore
    }

    sentences
  }
}

let segmentWords = (t, text: string): array<string> => {
  if isCJK(t.locale) {
    // CJK: each character is roughly a word
    text
    ->String.split("")
    ->Array.filter(c => {
      let trimmed = c->String.trim
      trimmed != "" && !(%re("/[.,!?。！？、；：\"'()（）「」『』【】]/")->RegExp.test(c))
    })
  } else {
    // Western: split on whitespace and punctuation
    text
    ->String.splitByRegExp(%re("/[\s,;:\"'()\[\]]+/"))
    ->Array.filterMap(x => x)
    ->Array.map(s => {
      // Trim punctuation from edges
      s->String.replaceAllRegExp(%re("/^[.,!?]+|[.,!?]+$/g"), "")
    })
    ->Array.filter(s => s != "")
  }
}

let wordCount = (t, text) => Array.length(segmentWords(t, text))

let sentenceCount = (t, text) => Array.length(segmentSentences(t, text))

let charCount = text => {
  text
  ->String.split("")
  ->Array.filter(c => c->String.trim != "")
  ->Array.length
}

let segmentSentencesWithPositions = (t, text: string): array<segment> => {
  let sentences = segmentSentences(t, text)
  let result = []
  let pos = ref(0)

  sentences->Array.forEach(sentence => {
    // Find this sentence in the original text
    let idx = text->String.indexOfFrom(sentence, pos.contents)
    if idx >= 0 {
      result->Array.push({
        text: sentence,
        start: idx,
        end_: idx + String.length(sentence),
      })->ignore
      pos := idx + String.length(sentence)
    }
  })

  result
}

let segmentWordsWithPositions = (t, text: string): array<segment> => {
  let words = segmentWords(t, text)
  let result = []
  let pos = ref(0)

  words->Array.forEach(word => {
    let idx = text->String.indexOfFrom(word, pos.contents)
    if idx >= 0 {
      result->Array.push({
        text: word,
        start: idx,
        end_: idx + String.length(word),
      })->ignore
      pos := idx + String.length(word)
    }
  })

  result
}
