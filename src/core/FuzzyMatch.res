// FuzzyMatch - Approximate string matching (agrep-style)
// SPDX-License-Identifier: AGPL-3.0-or-later

type match = {
  text: string,
  score: float,
  distance: int,
}

type config = {
  threshold: float,
  maxResults: int,
}

let make = () => {
  threshold: 0.6,
  maxResults: 10,
}

let withThreshold = (config, threshold) => {
  ...config,
  threshold: Js.Math.min_float(1.0, Js.Math.max_float(0.0, threshold)),
}

let withMaxResults = (config, maxResults) => {
  ...config,
  maxResults: Js.Math.max_int(1, maxResults),
}

// Levenshtein distance implementation
let levenshteinDistance = (a: string, b: string): int => {
  let aChars = a->String.split("")
  let bChars = b->String.split("")
  let aLen = Array.length(aChars)
  let bLen = Array.length(bChars)

  if aLen == 0 {
    bLen
  } else if bLen == 0 {
    aLen
  } else {
    // Create matrix
    let matrix = Array.make(aLen + 1, Array.make(bLen + 1, 0))

    // Initialize first row and column
    for i in 0 to aLen {
      matrix[i] = Array.make(bLen + 1, 0)
      matrix[i][0] = i
    }
    for j in 0 to bLen {
      matrix[0][j] = j
    }

    // Fill matrix
    for i in 1 to aLen {
      for j in 1 to bLen {
        let cost = if aChars[i - 1] == bChars[j - 1] { 0 } else { 1 }
        matrix[i][j] = Js.Math.min_int(
          Js.Math.min_int(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        )
      }
    }

    matrix[aLen][bLen]
  }
}

// Damerau-Levenshtein (includes transpositions)
let damerauLevenshteinDistance = (a: string, b: string): int => {
  let aChars = a->String.split("")
  let bChars = b->String.split("")
  let aLen = Array.length(aChars)
  let bLen = Array.length(bChars)

  if aLen == 0 {
    bLen
  } else if bLen == 0 {
    aLen
  } else {
    let matrix = Array.make(aLen + 1, Array.make(bLen + 1, 0))

    for i in 0 to aLen {
      matrix[i] = Array.make(bLen + 1, 0)
      matrix[i][0] = i
    }
    for j in 0 to bLen {
      matrix[0][j] = j
    }

    for i in 1 to aLen {
      for j in 1 to bLen {
        let cost = if aChars[i - 1] == bChars[j - 1] { 0 } else { 1 }

        matrix[i][j] = Js.Math.min_int(
          Js.Math.min_int(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        )

        // Transposition
        if i > 1 && j > 1 && aChars[i - 1] == bChars[j - 2] && aChars[i - 2] == bChars[j - 1] {
          matrix[i][j] = Js.Math.min_int(matrix[i][j], matrix[i - 2][j - 2] + cost)
        }
      }
    }

    matrix[aLen][bLen]
  }
}

let similarity = (a: string, b: string): float => {
  let dist = levenshteinDistance(a, b)
  let maxLen = Js.Math.max_int(String.length(a), String.length(b))
  if maxLen == 0 {
    1.0
  } else {
    1.0 -. Int.toFloat(dist) /. Int.toFloat(maxLen)
  }
}

let findMatches = (config, ~query: string, ~corpus: array<string>): array<match> => {
  let queryLower = query->String.toLowerCase
  let matches =
    corpus
    ->Array.map(text => {
      let textLower = text->String.toLowerCase
      let dist = levenshteinDistance(queryLower, textLower)
      let maxLen = Js.Math.max_int(String.length(queryLower), String.length(textLower))
      let score = if maxLen == 0 {
        1.0
      } else {
        1.0 -. Int.toFloat(dist) /. Int.toFloat(maxLen)
      }
      {text, score, distance: dist}
    })
    ->Array.filter(m => m.score >= config.threshold)
    ->Array.toSorted((a, b) => b.score -. a.score)

  matches->Array.slice(~start=0, ~end=config.maxResults)
}

let bestMatch = (config, ~query: string, ~candidates: array<string>): option<match> => {
  let matches = findMatches(config, ~query, ~corpus=candidates)
  matches->Array.get(0)
}

let agrep = (~pattern: string, ~text: string, ~maxDistance: int): bool => {
  levenshteinDistance(pattern, text) <= maxDistance
}

let ngramSimilarity = (~a: string, ~b: string, ~n: int): float => {
  let aChars = a->String.toLowerCase->String.split("")
  let bChars = b->String.toLowerCase->String.split("")

  if Array.length(aChars) < n || Array.length(bChars) < n {
    if a->String.toLowerCase == b->String.toLowerCase {
      1.0
    } else {
      0.0
    }
  } else {
    // Generate n-grams as arrays of chars
    let getNgrams = chars => {
      let result = []
      for i in 0 to Array.length(chars) - n {
        let ngram = Array.slice(chars, ~start=i, ~end=i + n)->Array.join("")
        result->Array.push(ngram)->ignore
      }
      result
    }

    let aNgrams = getNgrams(aChars)
    let bNgrams = getNgrams(bChars)

    // Convert to sets and compute Jaccard
    let aSet = Set.fromArray(aNgrams)
    let bSet = Set.fromArray(bNgrams)

    let intersection = aSet->Set.values->Iterator.toArray->Array.filter(x => bSet->Set.has(x))
    let union = Set.union(aSet, bSet)

    let unionSize = union->Set.size
    if unionSize == 0 {
      1.0
    } else {
      Int.toFloat(Array.length(intersection)) /. Int.toFloat(unionSize)
    }
  }
}

let generateNgrams = (text: string, ~n: int): array<string> => {
  let chars = text->String.toLowerCase->String.split("")
  if Array.length(chars) < n {
    [text->String.toLowerCase]
  } else {
    let result = []
    for i in 0 to Array.length(chars) - n {
      let ngram = Array.slice(chars, ~start=i, ~end=i + n)->Array.join("")
      result->Array.push(ngram)->ignore
    }
    result
  }
}
