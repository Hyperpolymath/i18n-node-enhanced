// Segmenter - Sentence and word boundary detection
// SPDX-License-Identifier: AGPL-3.0-or-later

// Segmenter for a specific locale
type t

// Create segmenter for locale
let make: Locale.t => t

// Create from locale string
let fromString: string => t

// Split text into sentences
let segmentSentences: (t, string) => array<string>

// Split text into words
let segmentWords: (t, string) => array<string>

// Get word count
let wordCount: (t, string) => int

// Get sentence count
let sentenceCount: (t, string) => int

// Get character count (excluding whitespace)
let charCount: string => int

// Segment with positions (for highlighting)
type segment = {
  text: string,
  start: int,
  end_: int,
}

let segmentSentencesWithPositions: (t, string) => array<segment>
let segmentWordsWithPositions: (t, string) => array<segment>
