// FuzzyMatch - Approximate string matching (agrep-style)
// SPDX-License-Identifier: AGPL-3.0-or-later

// Match result with score and distance
type match = {
  text: string,
  score: float,     // 0.0 to 1.0 similarity
  distance: int,    // Levenshtein edit distance
}

// Matcher configuration
type config

// Create matcher with default settings (60% threshold, 10 max results)
let make: unit => config

// Set minimum similarity threshold (0.0 to 1.0)
let withThreshold: (config, float) => config

// Set maximum number of results
let withMaxResults: (config, int) => config

// Calculate Levenshtein distance between two strings
let levenshteinDistance: (string, string) => int

// Calculate Damerau-Levenshtein distance (includes transpositions)
let damerauLevenshteinDistance: (string, string) => int

// Calculate similarity score (0.0 to 1.0)
let similarity: (string, string) => float

// Find matches in a corpus above threshold
let findMatches: (config, ~query: string, ~corpus: array<string>) => array<match>

// Find the best single match
let bestMatch: (config, ~query: string, ~candidates: array<string>) => option<match>

// agrep-style: does text match pattern within max edit distance?
let agrep: (~pattern: string, ~text: string, ~maxDistance: int) => bool

// N-gram based similarity (Jaccard index)
let ngramSimilarity: (~a: string, ~b: string, ~n: int) => float

// Generate n-grams from text
let generateNgrams: (string, ~n: int) => array<string>
