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
  threshold: Math.min(1.0, Math.max(0.0, threshold)),
}

let withMaxResults = (config, maxResults) => {
  ...config,
  maxResults: Math.Int.max(1, maxResults),
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
    // Create matrix - use unsafe access for performance (bounds checked by loop)
    let matrix = Array.make(~length=aLen + 1, Array.make(~length=bLen + 1, 0))

    // Initialize first row and column
    for i in 0 to aLen {
      Array.setUnsafe(matrix, i, Array.make(~length=bLen + 1, 0))
      let row = Array.getUnsafe(matrix, i)
      Array.setUnsafe(row, 0, i)
    }
    for j in 0 to bLen {
      let row0 = Array.getUnsafe(matrix, 0)
      Array.setUnsafe(row0, j, j)
    }

    // Fill matrix
    for i in 1 to aLen {
      for j in 1 to bLen {
        let aChar = Array.getUnsafe(aChars, i - 1)
        let bChar = Array.getUnsafe(bChars, j - 1)
        let cost = if aChar == bChar { 0 } else { 1 }
        let rowI = Array.getUnsafe(matrix, i)
        let rowIM1 = Array.getUnsafe(matrix, i - 1)
        let val1 = Array.getUnsafe(rowIM1, j) + 1
        let val2 = Array.getUnsafe(rowI, j - 1) + 1
        let val3 = Array.getUnsafe(rowIM1, j - 1) + cost
        Array.setUnsafe(rowI, j, Math.Int.min(Math.Int.min(val1, val2), val3))
      }
    }

    let lastRow = Array.getUnsafe(matrix, aLen)
    Array.getUnsafe(lastRow, bLen)
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
    let matrix = Array.make(~length=aLen + 1, Array.make(~length=bLen + 1, 0))

    for i in 0 to aLen {
      Array.setUnsafe(matrix, i, Array.make(~length=bLen + 1, 0))
      let row = Array.getUnsafe(matrix, i)
      Array.setUnsafe(row, 0, i)
    }
    for j in 0 to bLen {
      let row0 = Array.getUnsafe(matrix, 0)
      Array.setUnsafe(row0, j, j)
    }

    for i in 1 to aLen {
      for j in 1 to bLen {
        let aCharI = Array.getUnsafe(aChars, i - 1)
        let bCharJ = Array.getUnsafe(bChars, j - 1)
        let cost = if aCharI == bCharJ { 0 } else { 1 }

        let rowI = Array.getUnsafe(matrix, i)
        let rowIM1 = Array.getUnsafe(matrix, i - 1)
        let val1 = Array.getUnsafe(rowIM1, j) + 1
        let val2 = Array.getUnsafe(rowI, j - 1) + 1
        let val3 = Array.getUnsafe(rowIM1, j - 1) + cost
        Array.setUnsafe(rowI, j, Math.Int.min(Math.Int.min(val1, val2), val3))

        // Transposition
        if i > 1 && j > 1 {
          let bCharJM1 = Array.getUnsafe(bChars, j - 2)
          let aCharIM1 = Array.getUnsafe(aChars, i - 2)
          if aCharI == bCharJM1 && aCharIM1 == bCharJ {
            let rowIM2 = Array.getUnsafe(matrix, i - 2)
            let current = Array.getUnsafe(rowI, j)
            let trans = Array.getUnsafe(rowIM2, j - 2) + cost
            Array.setUnsafe(rowI, j, Math.Int.min(current, trans))
          }
        }
      }
    }

    let lastRow = Array.getUnsafe(matrix, aLen)
    Array.getUnsafe(lastRow, bLen)
  }
}

let similarity = (a: string, b: string): float => {
  let dist = levenshteinDistance(a, b)
  let maxLen = Math.Int.max(String.length(a), String.length(b))
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
      let maxLen = Math.Int.max(String.length(queryLower), String.length(textLower))
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
